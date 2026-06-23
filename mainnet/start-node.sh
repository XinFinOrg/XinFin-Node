#!/bin/bash

if [ ! -d /work/xdcchain/XDC/chaindata ]; then
    wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain | awk -F '[{}]' '{print $2}')
    echo "Initializing Genesis Block"
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

# create log file with timestamp
DATE="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/work/xdcchain/xdc-${DATE}.log"

sync_mode=full

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
    --store-reward
    --nat "extip:${INSTANCE_IP}"
)

if [[ "${store_reward}" == "true" ]]; then
    args+=(--store-reward)
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
