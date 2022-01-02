#!/bin/bash

if [ ! -d /work/xdcchain-testnet/XDC/chaindata ]
then
  wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain-testnet | awk -v FS="({|})" '{print $2}')
  echo "Initializing Testnet Genesis Block"
  echo $wallet
  coinbaseaddr="$wallet"
  coinbasefile=/work/xdcchain-testnet/coinbase.txt
  touch $coinbasefile
  if [ -f "$coinbasefile" ]
  then 
      echo "$coinbaseaddr" > "$coinbasefile"
  cat xdcchain-testnet/keystore/* >> "$coinbasefile"
  fi
  XDC --datadir /work/xdcchain-testnet init /work/testnetgenesis.json
else
  wallet=$(XDC account list --datadir /work/xdcchain-testnet| head -n 1 | awk -v FS="({|})" '{print $2}')
fi

input="/work/testnetbootnodes.list"
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
netstats="${INSTANCE_NAME}:xdc_xinfin_apothem_network_stats@stats.apothem.network:2000"

echo "Starting nodes with $bootnodes ..."
XDC --ethstats ${netstats} --gcmode=archive --bootnodes ${bootnodes} --syncmode ${NODE_TYPE} --datadir /work/xdcchain-testnet --networkid 51 -port 30304 --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8555 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS --rpcvhosts "*" --unlock "${wallet}" --password /work/.pwd --mine --gasprice "1" --targetgaslimit "420000000" --verbosity 3 --ws --wsaddr=0.0.0.0 --wsport 8556 --wsorigins "*" 2>&1 >>/work/xdcchain-testnet/xdc.log | tee --append /work/xdcchain-testnet/xdc.log
