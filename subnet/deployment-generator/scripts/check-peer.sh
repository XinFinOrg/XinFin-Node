#!/bin/bash

resp=$(curl -s --location "http://localhost:8545" \
--header 'Content-Type: application/json' \
--data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}')
echo $resp
num_peers=$(echo $resp | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
num_peers_dec=$(printf "%d\n" $num_peers)
echo "peers: $num_peers_dec"