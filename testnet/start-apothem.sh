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

# Peer whitelist: when /work/whitelist.list lists enodes, only talk to those peers
whitelist_args=()
whitelist_file="/work/whitelist.list"
if [[ "${PEER_WHITELIST:-true}" != "false" && -f "${whitelist_file}" ]]; then
    whitelist=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(echo "$line" | tr -d '[:space:]')"
        [[ -z "$line" ]] && continue
        if [[ ! "$line" =~ ^enode://[0-9a-fA-F]{128}@[^:@]+:[0-9]+$ ]]; then
            echo "ERROR: invalid whitelist entry, expected enode://<node id>@<ip>:<port>: $line"
            exit 1
        fi
        whitelist+=("$line")
    done <"${whitelist_file}"
    if [[ ${#whitelist[@]} -gt 0 ]]; then
        whitelist_toml=$(printf '"%s", ' "${whitelist[@]}")
        whitelist_toml="[${whitelist_toml%, }]"
        whitelist_config=/work/xdcchain/p2p-whitelist.toml
        {
            echo "[Node.P2P]"
            echo "StaticNodes = ${whitelist_toml}"
            echo "TrustedNodes = ${whitelist_toml}"
        } >"${whitelist_config}"
        whitelist_args=(
            --config "${whitelist_config}"
            --nodiscover
        )
        # --peers-allowlist and --peers-denylist are mutually exclusive in XDC:
        # regular nodes only accept the listed peers, the hub accepts everyone
        # except the peers in PEER_DENYLIST.
        if [[ "${PEER_WHITELIST_HUB}" == "true" ]]; then
            if [[ -n "${PEER_DENYLIST}" ]]; then
                whitelist_args+=(--peers-denylist "${PEER_DENYLIST}")
            fi
            echo "Peer whitelist enabled in hub mode with ${#whitelist[@]} static peers, denylist: ${PEER_DENYLIST:-none}"
        else
            allowlist=$(IFS=,; echo "${whitelist[*]}")
            whitelist_args+=(--peers-allowlist "${allowlist}")
            echo "Peer whitelist enabled with ${#whitelist[@]} peers, all other peers are rejected"
        fi
    fi
fi

log_level=2
if test -z "$LOG_LEVEL"
then
  echo "Log level not set, default to verbosity of $log_level"
else
  echo "Log level found, set to $LOG_LEVEL"
  log_level=$LOG_LEVEL
fi

# create log file with timestamp
DATE="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/work/xdcchain/xdc-${DATE}.log"

sync_mode="${SYNC_MODE:-full}"
echo "Sync mode: $sync_mode"

# Build pivot args for fast sync
pivot_args=()
if [[ "${sync_mode}" == "fast" ]]; then
    if [[ -z "${FASTSYNC_PIVOT_NUMBER}" || -z "${FASTSYNC_PIVOT_HASH}" || -z "${FASTSYNC_PIVOT_ROOT}" ]]; then
        echo "ERROR: SYNC_MODE=fast requires FASTSYNC_PIVOT_NUMBER, FASTSYNC_PIVOT_HASH, and FASTSYNC_PIVOT_ROOT to be set."
        exit 1
    fi
    pivot_args=(
        --fastsyncpivotnumber "${FASTSYNC_PIVOT_NUMBER}"
        --fastsyncpivothash "${FASTSYNC_PIVOT_HASH}"
        --fastsyncpivotroot "${FASTSYNC_PIVOT_ROOT}"
    )
fi

# Set store_reward from STORE_REWARD env or default to 'false'
store_reward=false
if test -z "$STORE_REWARD"; then
    echo "STORE_REWARD not set, default to false"
else
    echo "STORE_REWARD found, set to $STORE_REWARD"
    store_reward=$STORE_REWARD
fi

# Set gc_mode from GC_MODE env or default to 'archive'
gc_mode=archive
if test -z "$GC_MODE"; then
    echo "GC_MODE not set, default to archive" # full or archive
else
    echo "GC_MODE found, set to $GC_MODE"
    gc_mode=$GC_MODE
fi

# Set chain_config_mismatch_policy from CHAIN_CONFIG_MISMATCH_POLICY env or default to 'update-config-only'
chain_config_mismatch_policy=update-config-only
if test -z "$CHAIN_CONFIG_MISMATCH_POLICY"; then
    echo "CHAIN_CONFIG_MISMATCH_POLICY not set, default to update-config-only" # exit, rewind-and-update, update-config-only or ignore-mismatch
else
    echo "CHAIN_CONFIG_MISMATCH_POLICY found, set to $CHAIN_CONFIG_MISMATCH_POLICY"
    chain_config_mismatch_policy=$CHAIN_CONFIG_MISMATCH_POLICY
fi

INSTANCE_IP=$(curl https://checkip.amazonaws.com)
netstats="${NODE_NAME}:xdc_xinfin_apothem_network_stats@stats.apothem.network:2000"

echo "Starting nodes with $bootnodes ..."
args=(
    --ethstats "${netstats}"
    --bootnodes "${bootnodes}"
    --syncmode "${sync_mode}"
    --gcmode "${gc_mode}"
    --chain-config-mismatch-policy "${chain_config_mismatch_policy}"
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
)

if [[ "${store_reward}" == "true" ]]; then
    args+=(--store-reward)
fi

if [[ ${#pivot_args[@]} -gt 0 ]]; then
    args+=("${pivot_args[@]}")
fi

if [[ ${#whitelist_args[@]} -gt 0 ]]; then
    args+=("${whitelist_args[@]}")
fi

# RPC and WebSocket configuration - exact match required for security
if [[ "${ENABLE_RPC}" == "true" ]]; then
    args+=(
        --http
        --http-addr "0.0.0.0"
        --http-port "${RPC_PORT}"
        --http-api "${API}"
        --http-corsdomain "${ALLOWED_ORIGINS}"
        --http-vhosts "${RPC_VHOSTS}"
    )
else
    # When not "true", explicitly disable RPC to avoid unintended exposure
    args+=(
        --http=false
    )
fi

if [[ "${ENABLE_WS}" == "true" ]]; then
    args+=(
        --ws
        --ws-addr "0.0.0.0"
        --ws-port "${WS_PORT}"
        --ws-api "${API}"
        --ws-origins "${ALLOWED_ORIGINS}"
    )
else
    # When not "true", explicitly disable WebSocket to avoid unintended exposure
    args+=(
        --ws=false
    )
fi

XDC "${args[@]}" 2>&1 >>"${LOG_FILE}" | tee -a "${LOG_FILE}"
