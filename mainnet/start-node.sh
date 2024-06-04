#!/bin/bash

if [ ! -d /work/xdcchain/XDC/chaindata ]
then
  wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain | awk -F '[{}]' '{print $2}')
  echo "Initalizing Genesis Block"
  coinbaseaddr="$wallet"
  coinbasefile=/work/xdcchain/coinbase.txt
  touch $coinbasefile
  if [ -f "$coinbasefile" ]
  then
      echo "$coinbaseaddr" > "$coinbasefile"
  fi
  XDC --datadir /work/xdcchain init /work/genesis.json
else
  wallet=$(XDC account list --datadir /work/xdcchain| head -n 1 | awk -F '[{}]' '{print $2}')
fi

input="/work/bootnodes.list"
bootnodes=""
while IFS= read -r line
do
    if [ -z "${bootnodes}" ]
    then
        bootnodes=$line
    else
        bootnodes="${bootnodes},$line"
    fi
done < "$input"
INSTANCE_IP=$(curl https://checkip.amazonaws.com)
netstats="${INSTANCE_NAME}:xinfin_xdpos_hybrid_network_stats@stats.xinfin.network:3000"

echo "Starting nodes with $bootnodes ..."
XDC --ethstats ${netstats} --bootnodes ${bootnodes} --syncmode ${NODE_TYPE} --datadir /work/xdcchain --networkid 50 -port 30303 --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8545 --rpcapi db,eth,debug,net,shh,txpool,personal,web3,XDPoS --rpcvhosts "*"  --ws --wsaddr="0.0.0.0" --wsorigins "*" --wsport 8546 --wsapi db,eth,debug,net,shh,txpool,personal,web3,XDPoS  --unlock "${wallet}" --password /work/.pwd --mine --gasprice "1" --targetgaslimit "420000000" --verbosity 3 2>&1 >>/work/xdcchain/xdc.log | tee -a /work/xdcchain/xdc.log
