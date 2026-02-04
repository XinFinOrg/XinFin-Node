#!/bin/bash
if [ ! -d /work/xdcchain/XDC/chaindata ]; then
    echo $PRIVATE_KEY >>/tmp/key
    wallet=$(XDC account import --password .pwd --datadir /work/xdcchain /tmp/key | awk -F '[{}]' '{print $2}')
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

# Set sync_mode from SYNC_MODE env or default to 'full'
sync_mode=full
if test -z "$SYNC_MODE"; then
    echo "SYNC_MODE not set, default to $sync_mode" # full or fast
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
netstats="${wallet}_${INSTANCE_IP}:xinfin_xdpos_hybrid_network_stats@devnetstats.hashlabs.apothem.network:1999"

echo "Starting nodes with $bootnodes ..."
args=(
    --ethstats "${netstats}"
    --gcmode "${gc_mode}"
    --bootnodes "${bootnodes}"
    --syncmode "${sync_mode}"
    --datadir /work/xdcchain
    --networkid 551
    --port 30303
    --unlock "${wallet}"
    --password /work/.pwd
    --gasprice "1"
    --targetgaslimit "50000000"
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

XDC "${args[@]}" 2>&1 >>"${LOG_FILE}" | tee -a "${LOG_FILE}"
