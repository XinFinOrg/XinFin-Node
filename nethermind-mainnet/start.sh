#!/bin/bash

network="${NETWORK:-xdc}"
log_level="${NETHERMIND_LOG_LEVEL:-info}"
rpc_port="${RPC_PORT:-8515}"
echo "Network: $network, log level: $log_level, RPC port: $rpc_port"

# Build a comma-separated bootnode list from the mounted bootnodes.list
input="/nethermind/bootnodes.list"
bootnodes=""
count=0
if [ -f "$input" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line//$'\r'/}"
        [ -z "${line// /}" ] && continue
        count=$((count + 1))
        if [ -z "${bootnodes}" ]; then
            bootnodes=$line
        else
            bootnodes="${bootnodes},$line"
        fi
    done <"$input"
fi

args=(
    --config="${network}"
    --datadir=/nethermind/data
    --log="${log_level}"
    --JsonRpc.Enabled=true
    --JsonRpc.Host=0.0.0.0
    --JsonRpc.Port="${rpc_port}"
    --JsonRpc.EnabledModules=Eth,Health,Net,Parity,Proof,Rpc,Subscribe,Trace,TxPool,Web3,debug,Xdc
    --JsonRpc.JwtSecretFile=/tmp/jwt/jwtsecret
    --Network.DiscoveryPort=30301
    --Network.P2PPort=30301
    --Network.FilterPeersByRecentIp=false
    --HealthChecks.Enabled=true
)

if [ -n "${bootnodes}" ]; then
    echo "Starting with ${count} bootnodes from $input"
    args+=(--Network.Bootnodes="${bootnodes}")
else
    echo "No bootnodes in $input, using the chainspec's"
fi

# Hand off to the image's entrypoint, which sets up GC large pages and PGO before starting Nethermind
cd /nethermind
exec ./entrypoint.sh "${args[@]}"
