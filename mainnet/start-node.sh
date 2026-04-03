#!/bin/bash

if [ ! -d /work/xdcchain/XDC/chaindata ]; then
    wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain | awk -F '[{}]' '{print $2}')
    echo "Initalizing Genesis Block"
    coinbaseaddr="$wallet"
    coinbasefile=/work/xdcchain/coinbase.txt
    touch $coinbasefile
    if [ -f "$coinbasefile" ]; then
        echo "$coinbaseaddr" >"$coinbasefile"
    fi
    XDC init --datadir /work/xdcchain /work/genesis.json
else
    wallet=$(XDC account list --datadir /work/xdcchain | head -n 1 | awk -F '[{}]' '{print $2}')
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

log_level=2
if test -z "$LOG_LEVEL"
then
  echo "Log level not set, default to verbosity of $log_level"
else
  echo "Log level found, set to $LOG_LEVEL"
  log_level=$LOG_LEVEL
fi

log_dir=/work/xdcchain
stream_chunk_size=4096
stream_chunk_timeout=0.2
initial_log_day=""
initial_log_path=""

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

prepare_initial_log_file() {
    local timestamp=""
    local log_fd=""

    mkdir -p "${log_dir}" || return 1

    timestamp="$(date +%Y%m%d-%H%M%S)"
    initial_log_day="${timestamp%%-*}"
    initial_log_path="${log_dir}/xdc-${timestamp}.log"

    exec {log_fd}>>"${initial_log_path}" || return 1
    exec {log_fd}>&-
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
netstats="${INSTANCE_NAME}:xinfin_xdpos_hybrid_network_stats@stats.xinfin.network:3000"

echo "Starting nodes with $bootnodes ..."
args=(
    --ethstats "${netstats}"
    --bootnodes "${bootnodes}"
    --syncmode "${sync_mode}"
    --gcmode "${gc_mode}"
    --datadir /work/xdcchain
    --XDCx.datadir /work/xdcchain/XDCx
    --networkid 50
    --port 30303
    --unlock "${wallet}"
    --password /work/.pwd
    --mine
    --gasprice "1"
    --targetgaslimit "420000000"
    --verbosity "${log_level}"
)

# if ENABLE_RPC is true, add RPC related parameters
if echo "${ENABLE_RPC}" | grep -iq "true"; then
    args+=(
        --rpc
        --rpcaddr "${RPC_ADDR}"
        --rpcport "${RPC_PORT}"
        --rpcapi "${RPC_API}"
        --rpccorsdomain "${RPC_CORS_DOMAIN}"
        --rpcvhosts "${RPC_VHOSTS}"
        --store-reward
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
