#!/bin/bash

mkdir -p $PWD/work/xdcchain
touch $PWD/work/password.txt
cp ../genesis.json $PWD/work/genesis.json
cp ../bootnodes.list $PWD/work/bootnodes.list

if [ ! -d $PWD/work/xdcchain/XDC/chaindata ]
then
  wallet=$(XDC account new --password $PWD/work/password.txt --datadir $PWD/work/xdcchain | awk -v FS="({|})" '{print $2}')
  echo "Initalizing Genesis Block"
  coinbaseaddr="0x$wallet"
  coinbasefile=$PWD/work/xdcchain/coinbase.txt
  touch $coinbasefile
  if [ -f "$coinbasefile" ]
  then 
      echo "$coinbaseaddr" > "$coinbasefile"
  fi
  XDC --datadir $PWD/work/xdcchain init $PWD/work/genesis.json
else
  wallet=$(XDC account list --datadir $PWD/work/xdcchain| head -n 1 | awk -v FS="({|})" '{print $2}')
fi

input="$PWD/work/bootnodes.list"
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

netstats="XinFin_Masternode_macOS_$RANDOM:xinfin_network_stats@stats.testnet.xinfin.network:3000"

echo "Starting nodes with $bootnodes ..."
XDC --ethstats ${netstats} --bootnodes ${bootnodes} --syncmode full --datadir $PWD/work/xdcchain --networkid 853 -port 30303 --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts "*" --unlock "${wallet}" --password $PWD/work/password.txt --mine --gasprice "1" --targetgaslimit "420000000" --verbosity 3 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS 2>&1 >>$PWD/work/xdcchain/xdc.log



