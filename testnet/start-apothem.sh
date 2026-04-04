#!/bin/bash

if [ ! -d /work/xdcchain/XDC/chaindata ]; then
    wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain | awk -F '[{}]' '{print $2}')
    echo "Initializing Testnet Genesis Block"
    echo "wallet: $wallet"
    coinbaseaddr="$wallet"
    coinbasefile=/work/xdcchain/coinbase.txt
    touch $coinbasefile
    if [ -f "$coinbasefile" ]; then
        echo "$coinbaseaddr" >"$coinbasefile"
        cat xdcchain/keystore/* >>"$coinbasefile"
    fi
    XDC init --datadir /work/xdcchain /work/genesis.json
else
    wallet=$(XDC account list --datadir /work/xdcchain | head -n 1 | awk -F '[{}]' '{print $2}')
    echo "wallet: $wallet"
fi

input="/work/bootnodes.list"
bootnodes=""
while IFS= read -r line; do
    if [ -z "${bootnodes}" ]; then
        bootnodes=$line
    else
        bootnodes="${bootnodes},$line"
    fi
done <"$input"

log_level=3
if test -z "$LOG_LEVEL"
then
  echo "Log level not set, default to verbosity of $log_level"
else
  echo "Log level found, set to $LOG_LEVEL"
  log_level=$LOG_LEVEL
fi

log_dir=/work/xdcchain
log_keep_days=30
log_uncompressed_days=3
log_compress_lock_dir="${log_dir}/.log-compress.lock"
log_compress_lock_ready_file="${log_compress_lock_dir}/ready"
log_compress_lock_partial_stale_minutes=1
stream_chunk_size=4096
stream_chunk_timeout=0.2
initial_log_day=""
initial_log_path=""

if [[ -z "${LOG_KEEP_DAYS}" ]]; then
    echo "LOG_KEEP_DAYS not set, default to ${log_keep_days}"
elif [[ "${LOG_KEEP_DAYS}" =~ ^[0-9]+$ && "${LOG_KEEP_DAYS}" -ge 3 ]]; then
    echo "LOG_KEEP_DAYS found, set to ${LOG_KEEP_DAYS}"
    log_keep_days=${LOG_KEEP_DAYS}
else
    echo "Invalid LOG_KEEP_DAYS: ${LOG_KEEP_DAYS}. Expected an integer greater than or equal to 3." >&2
    exit 1
fi

if [[ -z "${LOG_UNCOMPRESSED_DAYS}" ]]; then
    echo "LOG_UNCOMPRESSED_DAYS not set, default to ${log_uncompressed_days}"
elif [[ "${LOG_UNCOMPRESSED_DAYS}" =~ ^[0-9]+$ && "${LOG_UNCOMPRESSED_DAYS}" -ge 2 ]]; then
    echo "LOG_UNCOMPRESSED_DAYS found, set to ${LOG_UNCOMPRESSED_DAYS}"
    log_uncompressed_days=${LOG_UNCOMPRESSED_DAYS}
else
    echo "Invalid LOG_UNCOMPRESSED_DAYS: ${LOG_UNCOMPRESSED_DAYS}. Expected an integer greater than or equal to 2." >&2
    exit 1
fi

if [[ "${log_uncompressed_days}" -gt "${log_keep_days}" ]]; then
    echo "Invalid log retention settings: LOG_UNCOMPRESSED_DAYS (${log_uncompressed_days}) cannot be greater than LOG_KEEP_DAYS (${log_keep_days})." >&2
    exit 1
fi

read_stream_chunk() {
    local stream_fd=$1
    local result_var=$2
    local chunk_data=""
    local read_status=0

    IFS= read -r -N "${stream_chunk_size}" -t "${stream_chunk_timeout}" chunk_data <"/proc/self/fd/${stream_fd}"
    read_status=$?
    printf -v "${result_var}" '%s' "${chunk_data}"

    return "${read_status}"
}

extract_log_date() {
    local log_name=$1

    parsed_log_date=""
    if [[ "${log_name}" =~ ^xdc-([0-9]{8})-[0-9]{6}\.log(\.gz)?$ ]]; then
        parsed_log_date="${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

get_process_start_time() {
    local pid=$1
    local start_time=""

    start_time="$(awk '{print $22}' "/proc/${pid}/stat" 2>/dev/null)"
    if [[ ! "${start_time}" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    printf '%s\n' "${start_time}"
}

get_process_pid_namespace() {
    local pid=$1
    local pid_namespace=""

    pid_namespace="$(readlink "/proc/${pid}/ns/pid" 2>/dev/null)"
    if [[ -z "${pid_namespace}" ]]; then
        return 1
    fi

    printf '%s\n' "${pid_namespace}"
}

lock_process_is_active() {
    local pid=$1
    local expected_start_time=$2
    local expected_pid_namespace=$3
    local current_start_time=""
    local current_pid_namespace=""

    if [[ ! "${pid}" =~ ^[0-9]+$ ]] || ! kill -0 "${pid}" 2>/dev/null; then
        return 1
    fi

    current_start_time="$(get_process_start_time "${pid}")" || return 1
    current_pid_namespace="$(get_process_pid_namespace "${pid}")" || return 1

    if [[ "${current_start_time}" != "${expected_start_time}" || "${current_pid_namespace}" != "${expected_pid_namespace}" ]]; then
        return 1
    fi

    return 0
}

cleanup_old_logs() {
    local retention_start_date=""
    local deleted_logs=0
    local log_file=""
    local log_name=""
    local log_date=""

    retention_start_date="$(date -d "-$((log_keep_days - 1)) days" +%Y%m%d)"

    while IFS= read -r -d '' log_file; do
        log_name="$(basename "${log_file}")"
        if extract_log_date "${log_name}"; then
            log_date="${parsed_log_date}"
            if [[ "${log_date}" < "${retention_start_date}" ]]; then
                echo "Deleting expired log file: ${log_file}"
                rm -f -- "${log_file}"
                deleted_logs=$((deleted_logs + 1))
            fi
        fi
    done < <(find "${log_dir}" -maxdepth 1 -type f \( -name 'xdc-*.log' -o -name 'xdc-*.log.gz' \) -print0)

    echo "Log retention: kept ${log_keep_days} day(s), removed ${deleted_logs} expired log file(s)"
}

compress_old_logs() {
    local active_log_path=$1
    local retention_start_date=""
    local uncompressed_start_date=""
    local compressed_logs=0
    local failed_logs=0
    local recovered_logs=0
    local log_file=""
    local log_name=""
    local log_date=""
    local final_gz=""
    local tmp_gz=""
    local invalid_archive_removed=0

    retention_start_date="$(date -d "-$((log_keep_days - 1)) days" +%Y%m%d)"
    uncompressed_start_date="$(date -d "-$((log_uncompressed_days - 1)) days" +%Y%m%d)"

    while IFS= read -r -d '' log_file; do
        if [[ "${log_file}" == "${active_log_path}" ]]; then
            continue
        fi

        log_name="$(basename "${log_file}")"
        if ! extract_log_date "${log_name}"; then
            continue
        fi

        log_date="${parsed_log_date}"
        if [[ "${log_date}" < "${retention_start_date}" || "${log_date}" > "${uncompressed_start_date}" || "${log_date}" == "${uncompressed_start_date}" ]]; then
            continue
        fi

        final_gz="${log_file}.gz"
        invalid_archive_removed=0
        if [[ -e "${final_gz}" ]]; then
            if gzip -t -- "${final_gz}" >/dev/null 2>&1; then
                if rm -f -- "${log_file}"; then
                    echo "Compressed log already exists for ${log_name}; removed leftover original log file"
                    recovered_logs=$((recovered_logs + 1))
                else
                    echo "Unable to remove leftover original log file for ${log_name}"
                    failed_logs=$((failed_logs + 1))
                fi
            else
                echo "Existing compressed log invalid for ${log_name}; recreating archive"
                if ! rm -f -- "${final_gz}"; then
                    echo "Unable to remove invalid compressed log for ${log_name}"
                    failed_logs=$((failed_logs + 1))
                    continue
                fi
                invalid_archive_removed=1
            fi

            if [[ "${invalid_archive_removed}" -eq 0 ]]; then
                continue
            fi
        fi

        tmp_gz="${final_gz}.tmp.${BASHPID:-$$}"
        rm -f -- "${tmp_gz}"
        echo "Compressing log file: ${log_name}"
        if gzip -c -- "${log_file}" >"${tmp_gz}" && mv -f -- "${tmp_gz}" "${final_gz}" && rm -f -- "${log_file}"; then
            compressed_logs=$((compressed_logs + 1))
        else
            rm -f -- "${tmp_gz}"
            echo "Log compression failed for ${log_name}; keeping original log file"
            failed_logs=$((failed_logs + 1))
        fi
    done < <(find "${log_dir}" -maxdepth 1 -type f -name 'xdc-*.log' -print0)

    echo "Log compression: compressed ${compressed_logs} file(s), recovered ${recovered_logs} file(s), failed ${failed_logs} file(s)"
}

log_compression_lock_is_ready() {
    [[ -f "${log_compress_lock_ready_file}" ]]
}

lock_directory_is_stale_partial() {
    find "${log_compress_lock_dir}" -maxdepth 0 -type d -mmin "+${log_compress_lock_partial_stale_minutes}" | grep -q .
}

cleanup_stale_log_temp_files() {
    local removed_temp_files=0
    local temp_file=""

    while IFS= read -r -d '' temp_file; do
        if rm -f -- "${temp_file}"; then
            removed_temp_files=$((removed_temp_files + 1))
        fi
    done < <(find "${log_dir}" -maxdepth 1 -type f -name 'xdc-*.log.gz.tmp.*' -print0)

    echo "Log compression cleanup: removed ${removed_temp_files} stale temp file(s)"
}

acquire_log_compression_lock() {
    local attempt=0
    local existing_pid=""
    local existing_start_time=""
    local existing_pid_namespace=""
    local current_pid=""
    local current_start_time=""
    local current_pid_namespace=""

    while [[ "${attempt}" -lt 2 ]]; do
        if mkdir "${log_compress_lock_dir}" 2>/dev/null; then
            current_pid="${BASHPID:-$$}"
            printf '%s\n' "${current_pid}" >"${log_compress_lock_dir}/pid"
            current_start_time="$(get_process_start_time "${current_pid}")" && printf '%s\n' "${current_start_time}" >"${log_compress_lock_dir}/start_time"
            current_pid_namespace="$(get_process_pid_namespace "${current_pid}")" && printf '%s\n' "${current_pid_namespace}" >"${log_compress_lock_dir}/pid_namespace"
            date -u +%Y-%m-%dT%H:%M:%SZ >"${log_compress_lock_dir}/started_at"
            : >"${log_compress_lock_ready_file}"
            return 0
        fi

        if ! log_compression_lock_is_ready; then
            if lock_directory_is_stale_partial; then
                echo "Recovering stale partial log compression lock"
                rm -rf -- "${log_compress_lock_dir}"
                attempt=$((attempt + 1))
                continue
            fi

            echo "Log compression lock is still initializing, skipping this cycle"
            return 1
        fi

        if [[ -f "${log_compress_lock_dir}/pid" ]]; then
            existing_pid="$(cat "${log_compress_lock_dir}/pid" 2>/dev/null)"
        fi
        if [[ -f "${log_compress_lock_dir}/start_time" ]]; then
            existing_start_time="$(cat "${log_compress_lock_dir}/start_time" 2>/dev/null)"
        fi
        if [[ -f "${log_compress_lock_dir}/pid_namespace" ]]; then
            existing_pid_namespace="$(cat "${log_compress_lock_dir}/pid_namespace" 2>/dev/null)"
        fi

        if [[ -n "${existing_start_time}" && -n "${existing_pid_namespace}" ]] && lock_process_is_active "${existing_pid}" "${existing_start_time}" "${existing_pid_namespace}"; then
            echo "Log compression already running with pid ${existing_pid}, skipping this cycle"
            return 1
        fi

        echo "Recovering stale log compression lock"
        rm -rf -- "${log_compress_lock_dir}"
        attempt=$((attempt + 1))
    done

    echo "Unable to acquire log compression lock, skipping this cycle"
    return 1
}

release_log_compression_lock() {
    rm -rf -- "${log_compress_lock_dir}"
}

compress_old_logs_with_lock() {
    local active_log_path=$1

    if ! command -v gzip >/dev/null 2>&1; then
        echo "gzip not available, skipping log compression"
        return 0
    fi

    if ! acquire_log_compression_lock; then
        return 0
    fi

    trap 'release_log_compression_lock' EXIT
    cleanup_stale_log_temp_files
    compress_old_logs "${active_log_path}"
}

run_log_compression_async() {
    local active_log_path=$1

    (
        if command -v ionice >/dev/null 2>&1; then
            ionice -c3 -p "${BASHPID:-$$}" >/dev/null 2>&1 || true
        fi
        if command -v renice >/dev/null 2>&1; then
            renice -n 19 -p "${BASHPID:-$$}" >/dev/null 2>&1 || true
        fi
        compress_old_logs_with_lock "${active_log_path}"
    ) &
}

prepare_initial_log_file() {
    local timestamp=""
    local log_fd=""

    mkdir -p "${log_dir}" || return 1

    timestamp="$(date +%Y%m%d-%H%M%S)"
    initial_log_day="${timestamp%%-*}"
    initial_log_path="${log_dir}/xdc-${timestamp}.log"

    exec {log_fd}>>"${initial_log_path}" || return 1
    exec {log_fd}>&-
    cleanup_old_logs
    run_log_compression_async "${initial_log_path}"
}

write_rotated_log_stream() {
    local current_day="${initial_log_day}"
    local log_fd=""
    local log_path="${initial_log_path}"
    local timestamp=""
    local chunk=""
    local read_status=0

    if [[ -n "${log_path}" ]]; then
        exec {log_fd}>>"${log_path}" || return 1
    fi

    while true; do
        read_stream_chunk 0 chunk
        read_status=$?

        if [[ "${read_status}" -gt 128 && -z "${chunk}" ]]; then
            continue
        fi

        if [[ -z "${chunk}" && "${read_status}" -ne 0 ]]; then
            break
        fi

        timestamp="$(date +%Y%m%d-%H%M%S)"

        if [[ "${timestamp%%-*}" != "${current_day}" ]]; then
            if [[ -n "${log_fd}" ]]; then
                exec {log_fd}>&-
            fi

            current_day="${timestamp%%-*}"
            log_path="${log_dir}/xdc-${timestamp}.log"
            exec {log_fd}>>"${log_path}" || return 1
            cleanup_old_logs
            run_log_compression_async "${log_path}"
        fi

        printf '%s' "${chunk}" >&${log_fd} || return 1
    done

    if [[ -n "${log_fd}" ]]; then
        exec {log_fd}>&-
    fi
}

log_writer_fd=""
log_writer_pid=""
xdc_read_fd=""
xdc_write_fd=""
xdc_pid=""
shutdown_requested=0
shutdown_exit_code=0

start_log_writer() {
    prepare_initial_log_file || return 1
    exec {log_writer_fd}> >(write_rotated_log_stream)
    log_writer_pid=$!
}

stop_log_writer() {
    local log_writer_exit_code=0

    if [[ -n "${log_writer_fd}" ]]; then
        exec {log_writer_fd}>&-
        log_writer_fd=""
    fi

    if [[ -n "${log_writer_pid}" ]]; then
        wait "${log_writer_pid}"
        log_writer_exit_code=$?
        log_writer_pid=""
    fi

    return "${log_writer_exit_code}"
}

start_xdc_stream() {
    coproc XDC_STREAM { exec XDC "${args[@]}" 2>&1; }
    xdc_pid=$XDC_STREAM_PID
    xdc_read_fd=${XDC_STREAM[0]}
    xdc_write_fd=${XDC_STREAM[1]}
    exec {xdc_write_fd}>&-
    xdc_write_fd=""
}

stop_xdc_stream() {
    local xdc_exit_code=0

    if [[ -n "${xdc_pid}" ]]; then
        wait "${xdc_pid}"
        xdc_exit_code=$?
        xdc_pid=""
    fi

    if [[ -n "${xdc_read_fd}" ]]; then
        exec {xdc_read_fd}<&-
        xdc_read_fd=""
    fi

    return "${xdc_exit_code}"
}

terminate_xdc_stream() {
    if [[ -n "${xdc_read_fd}" ]]; then
        exec {xdc_read_fd}<&-
        xdc_read_fd=""
    fi

    if [[ -n "${xdc_pid}" ]]; then
        kill "${xdc_pid}" 2>/dev/null || true
        wait "${xdc_pid}" 2>/dev/null || true
        xdc_pid=""
    fi
}

request_shutdown() {
    local signal_name=$1

    if [[ "${shutdown_requested}" -ne 0 ]]; then
        return
    fi

    shutdown_requested=1
    shutdown_exit_code=$((128 + $(kill -l "${signal_name}")))

    if [[ -n "${xdc_pid}" ]]; then
        kill -s "${signal_name}" "${xdc_pid}" 2>/dev/null || true
    fi
}

# Set sync_mode from SYNC_MODE env or default to 'full'
sync_mode=full
if test -z "$SYNC_MODE"; then
    echo "SYNC_MODE not set, default to full" # full or fast
else
    echo "SYNC_MODE found, set to $SYNC_MODE"
    sync_mode=$SYNC_MODE
fi

# Set gc_mode from GC_MODE env or default to 'archive'
gc_mode=archive
if test -z "$GC_MODE"; then
    echo "GC_MODE not set, default to archive" # full or archive
else
    echo "GC_MODE found, set to $GC_MODE"
    gc_mode=$GC_MODE
fi

INSTANCE_IP=$(curl https://checkip.amazonaws.com)
netstats="${NODE_NAME}:xdc_xinfin_apothem_network_stats@stats.apothem.network:2000"

echo "Starting nodes with $bootnodes ..."
args=(
    --ethstats "${netstats}"
    --bootnodes "${bootnodes}"
    --syncmode "${sync_mode}"
    --gcmode "${gc_mode}"
    --datadir /work/xdcchain
    --XDCx.datadir /work/xdcchain/XDCx
    --networkid 51
    --port 30312
    --unlock "${wallet}"
    --password /work/.pwd
    --mine
    --gasprice "1"
    --targetgaslimit "420000000"
    --verbosity "${log_level}"
    --store-reward
)

if echo "${ENABLE_RPC}" | grep -iq "true"; then
    args+=(
        --rpc
        --rpcaddr "${RPC_ADDR}"
        --rpcport "${RPC_PORT}"
        --rpcapi "${RPC_API}"
        --rpccorsdomain "${RPC_CORS_DOMAIN}"
        --rpcvhosts "${RPC_VHOSTS}"
        --ws
        --wsaddr "${WS_ADDR}"
        --wsport "${WS_PORT}"
        --wsapi "${WS_API}"
        --wsorigins "${WS_ORIGINS}"
    )
fi

set -o pipefail
trap 'request_shutdown TERM' TERM
trap 'request_shutdown INT' INT
start_log_writer || exit $?
start_xdc_stream
stream_exit_code=0
while true; do
    chunk=""
    read_stream_chunk "${xdc_read_fd}" chunk
    read_status=$?

    if [[ "${read_status}" -gt 128 && -z "${chunk}" ]]; then
        continue
    fi

    if [[ -z "${chunk}" && "${read_status}" -ne 0 ]]; then
        break
    fi

    printf '%s' "${chunk}" || {
        stream_exit_code=$?
        break
    }

    printf '%s' "${chunk}" >"/proc/self/fd/${log_writer_fd}" || {
        stream_exit_code=$?
        break
    }
done

xdc_exit_code=0
if [[ "${shutdown_requested}" -ne 0 ]]; then
    stop_xdc_stream
    xdc_exit_code=$?
elif [[ "${stream_exit_code}" -eq 0 ]]; then
    stop_xdc_stream
    xdc_exit_code=$?
else
    terminate_xdc_stream
fi

stop_log_writer
log_writer_exit_code=$?

trap - TERM INT

if [[ "${shutdown_requested}" -ne 0 ]]; then
    exit "${shutdown_exit_code}"
fi

if [[ "${xdc_exit_code}" -ne 0 ]]; then
    exit "${xdc_exit_code}"
fi

if [[ "${stream_exit_code}" -ne 0 ]]; then
    exit "${stream_exit_code}"
fi

exit "${log_writer_exit_code}"
