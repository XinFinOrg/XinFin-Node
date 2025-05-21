#!/bin/bash
container_name="mainnet_xinfinnetwork_1"
filename="enode.txt"

while IFS= read -r line || [[ -n "$line" ]]; do
  echo $line
  cmd='"admin.addPeer(\"'$line'\")"'
  cmd='cd xdcchain; XDC --exec '$cmd' attach XDC.ipc'
  resp=$(docker exec $container_name bash -c "$cmd")
  echo $resp 
done < "$filename"