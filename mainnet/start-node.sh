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

# create log file with timestamp
DATE="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/work/xdcchain/xdc-${DATE}.log"

INSTANCE_IP=$(curl https://checkip.amazonaws.com)
netstats="${INSTANCE_NAME}:xinfin_xdpos_hybrid_network_stats@stats.xinfin.network:3000"

echo "Starting nodes with $bootnodes ..."
args=(
    --ethstats "${netstats}"
    --bootnodes "${bootnodes}"
    --syncmode "${NODE_TYPE}"
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
if [ "$(echo $ENABLE_RPC | tr '[:upper:]' '[:lower:]')" = "true" ]; then
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


XDC "${args[@]}" 2>&1 >>"${LOG_FILE}" | tee -a "${LOG_FILE}"