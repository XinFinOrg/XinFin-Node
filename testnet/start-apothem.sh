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
    --networkid 51
    --port 30312
    --unlock "${wallet}"
    --password /work/.pwd
    --gasprice "1"
    --targetgaslimit "420000000"
    --verbosity "${log_level}"
    --store-reward
)

if echo "${ENABLE_RPC}" | grep -iq "true"; then
    args+=(
        --http
        --http-addr "${RPC_ADDR}"
        --http-port "${RPC_PORT}"
        --http-api "${RPC_API}"
        --http-corsdomain "${RPC_CORS_DOMAIN}"
        --http-vhosts "${RPC_VHOSTS}"
        --ws
        --ws-addr "${WS_ADDR}"
        --ws-port "${WS_PORT}"
        --ws-api "${WS_API}"
        --ws-origins "${WS_ORIGINS}"
    )
fi

XDC "${args[@]}" 2>&1 >>"${LOG_FILE}" | tee -a "${LOG_FILE}"
