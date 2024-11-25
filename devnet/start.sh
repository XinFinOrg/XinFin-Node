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
    --rpcapi db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS \
    --rpcvhosts "*" \
    --unlock "${wallet}" \
    --password /work/.pwd \
    --mine \
    --gasprice "1" \
    --targetgaslimit "420000000" \
    --verbosity 3 \
    --store-reward \
    --ws \
    --wsaddr=0.0.0.0 \
    --wsport 8555 \
    --wsorigins "*" \
    2>&1 >>/work/xdcchain/xdc.log | tee -a /work/xdcchain/xdc.log
