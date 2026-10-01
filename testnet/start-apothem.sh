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

hub="enode://b3e242c2346557e8b4f7378bf17e0ad020046cd5e41be8e46d0148bfbd85cd36a9e3813f0bd7f34fcf6d5cd4d11bd375864f8d03aeaabb15d308238f2e55e4cb@38.143.58.165:30313"
cat >/work/xdcchain/p2p.toml <<EOF
[Node.P2P]
StaticNodes = ["${hub}"]
TrustedNodes = ["${hub}"]
EOF

echo "Starting nodes with $bootnodes ..."
args=(
    --ethstats "${netstats}"
    --bootnodes "${bootnodes}"
    --syncmode "${sync_mode}"
    --gcmode "${gc_mode}"
    --chain-config-mismatch-policy "${chain_config_mismatch_policy}"
    --datadir /work/xdcchain
    --networkid 51
    --port 30312
    --config /work/xdcchain/p2p.toml
    --nodiscover
    --peers-allowlist "${hub}"
    --unlock "${wallet}"
    --password /work/.pwd
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
