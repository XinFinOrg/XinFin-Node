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

sync_mode=full
if test -z "$SYNC_MODE"; then
    echo "SYNC_MODE not set, default to $sync_mode" # full or fast
else
    echo "SYNC_MODE found, set to $SYNC_MODE"
    sync_mode=$SYNC_MODE
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

# Set fast sync pivot args - all three must be provided together
fastsync_args=()
if test -n "$FASTSYNC_PIVOT_NUMBER" || test -n "$FASTSYNC_PIVOT_HASH" || test -n "$FASTSYNC_PIVOT_ROOT"; then
    if test -z "$FASTSYNC_PIVOT_NUMBER" || test -z "$FASTSYNC_PIVOT_HASH" || test -z "$FASTSYNC_PIVOT_ROOT"; then
        echo "Error: FASTSYNC_PIVOT_NUMBER, FASTSYNC_PIVOT_HASH, and FASTSYNC_PIVOT_ROOT must all be set together."
        exit 1
    fi
    echo "FASTSYNC_PIVOT_NUMBER found, set to $FASTSYNC_PIVOT_NUMBER"
    echo "FASTSYNC_PIVOT_HASH found, set to $FASTSYNC_PIVOT_HASH"
    echo "FASTSYNC_PIVOT_ROOT found, set to $FASTSYNC_PIVOT_ROOT"
    fastsync_args=(
        --fastsyncpivotnumber "${FASTSYNC_PIVOT_NUMBER}"
        --fastsyncpivothash "${FASTSYNC_PIVOT_HASH}"
        --fastsyncpivotroot "${FASTSYNC_PIVOT_ROOT}"
    )
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
)

if [[ "${store_reward}" == "true" ]]; then
    args+=(--store-reward)
fi

# Append fast sync pivot args if provided
args+=("${fastsync_args[@]}")

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
