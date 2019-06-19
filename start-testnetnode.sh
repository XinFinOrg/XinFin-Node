#!/bin/bash

if [ ! -d /work/xdcchain-testnet/XDC/chaindata ]
then
  wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain-testnet | awk -v FS="({|})" '{print $2}')
  echo "Initalizing Testnet Genesis Block"
  coinbaseaddr="xdc$wallet"
  coinbasefile=/work/xdcchain-testnet/coinbase.txt
  touch $coinbasefile
  if [ -f "$coinbasefile" ]
  then 
      echo "$coinbaseaddr" > "$coinbasefile"
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

netstats="$INSTANCE_NAME:xdc_xinfin_apothem_network_stats@stats.apothem.network:2000"

echo "Starting nodes with $bootnodes ..."
XDC --ethstats ${netstats} --bootnodes ${bootnodes} --syncmode ${NODE_TYPE} --datadir /work/xdcchain-testnet --networkid 51 -port 30303 --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts "*" --unlock "${wallet}" --password /work/.pwd --mine --gasprice "1" --targetgaslimit "420000000" --verbosity 3 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS  --ws --wsaddr=0.0.0.0 --wsorigins * --wsport 855s5 2>&1 >>/work/xdcchain-testnet/xdc.log | tee --append /work/xdcchain-testnet/xdc.log
