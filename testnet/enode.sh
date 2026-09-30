#!/bin/bash
# Print this node's enode with its public IP, ready to paste into whitelist.list.
container_name="xdcnetwork-testnet-node"

enode=$(docker exec "$container_name" XDC attach --exec "admin.nodeInfo.enode" /work/xdcchain/XDC.ipc | tr -d '"')
if [[ "$enode" != enode://* ]]; then
    echo "Failed to read enode from $container_name: $enode" >&2
    exit 1
fi
node_id=${enode#enode://}
node_id=${node_id%%@*}
port=${enode##*:}
port=${port%%\?*}
public_ip=$(curl -s https://checkip.amazonaws.com)

echo "enode://${node_id}@${public_ip}:${port}"
