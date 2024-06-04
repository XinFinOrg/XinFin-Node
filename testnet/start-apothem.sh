#!/bin/bash

if [ ! -d /work/xdcchain/XDC/chaindata ]
then
  wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain | awk -F '[{}]' '{print $2}')
  echo "Initializing Testnet Genesis Block"
  echo "wallet: $wallet"
  coinbaseaddr="$wallet"
  coinbasefile=/work/xdcchain/coinbase.txt
  touch $coinbasefile
  if [ -f "$coinbasefile" ]
  then
      echo "$coinbaseaddr" > "$coinbasefile"
  cat xdcchain/keystore/* >> "$coinbasefile"
  fi
  XDC --datadir /work/xdcchain init /work/genesis.json
else
  wallet=$(XDC account list --datadir /work/xdcchain| head -n 1 | awk -F '[{}]' '{print $2}')
  echo "wallet: $wallet"
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
netstats="${NODE_NAME}:xdc_xinfin_apothem_network_stats@stats.apothem.network:2000"

echo "Starting nodes with $bootnodes ..."
XDC --ethstats ${netstats} --gcmode=archive \
    --bootnodes ${bootnodes} --syncmode ${NODE_TYPE} \
    --datadir /work/xdcchain \
    --networkid 51 -port 30304 \
    --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 \
    --rpcport 8555 --rpcapi db,eth,debug,net,shh,txpool,personal,web3,XDPoS \
    --rpcvhosts "*" --unlock "${wallet}" --password /work/.pwd \
    --mine --gasprice "1" --targetgaslimit "420000000" \
    --verbosity 2 --ws --wsaddr=0.0.0.0 --wsport 8556 \
    --wsorigins "*" 2>&1 >>/work/xdcchain/xdc.log | tee -a /work/xdcchain/xdc.log
