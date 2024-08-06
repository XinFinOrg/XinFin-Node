#!/bin/bash

echo "getting latest block"
resp=$(curl -s --location 'http://localhost:8545' \
--header 'Content-Type: application/json' \
--data '{"jsonrpc":"2.0","method":"XDPoS_getV2BlockByNumber","params":["latest"],"id":1}')

num=$(echo $resp | jq -r .result.Number)
echo $num

if [[ $num == "null" ]] || [[ $num == "" ]]; then
  echo "no block has been mined, please check if nodes are peering properly"
  exit
else
  for i in 2 3 4
  do 
    sleep 3
    echo "getting latest block $i"
    resp=$(curl -s --location 'http://localhost:8545' \
  --header 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","method":"XDPoS_getV2BlockByNumber","params":["latest"],"id":1}')
    nextnum=$(echo $resp | jq -r .result.Number)
    echo $nextnum
  done
fi

if [[ $nextnum > $num ]]; then
  echo "subnet successfully running and mining blocks"
fi
