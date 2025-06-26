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

INSTANCE_IP=$(curl https://checkip.amazonaws.com)
netstats="${wallet}_${INSTANCE_IP}:xinfin_xdpos_hybrid_network_stats@devnetstats.hashlabs.apothem.network:1999"

echo "Starting nodes with $bootnodes ..."

XDC \
    --ethstats ${netstats} \
    --gcmode=archive \
    --bootnodes ${bootnodes} \
    --syncmode ${NODE_TYPE} \
    --datadir /work/xdcchain \
    --networkid 551 \
    --XDCx.datadir /work/xdcchain/XDCx \
    --port 30303 \
    --rpc \
    --rpccorsdomain "*" \
    --rpcaddr 0.0.0.0 \
    --rpcport 8545 \
    --rpcapi db,eth,miner,net,txpool,web3,XDPoS \
    --rpcvhosts "*" \
    --unlock "${wallet}" \
    --password /work/.pwd \
    --mine \
    --gasprice "1" \
    --targetgaslimit "50000000" \
    --verbosity ${log_level} \
    --store-reward \
    --ws \
    --wsaddr=0.0.0.0 \
    --wsport 8555 \
    --wsorigins "*" \
    2>&1 >>"${LOG_FILE}" | tee -a "${LOG_FILE}"
