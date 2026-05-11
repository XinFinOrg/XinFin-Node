#!/bin/bash
cd $(dirname "$0")

container_name="xdcnetwork-devnet-node"
filename="../bootnodes.list"

while IFS= read -r line || [[ -n "$line" ]]; do
  echo $line
  cmd='"admin.addPeer(\"'$line'\")"'
  cmd='cd xdcchain; XDC --exec '$cmd' attach XDC.ipc'
  resp=$(docker exec $container_name bash -c "$cmd")
  echo $resp 
done < "$filename"