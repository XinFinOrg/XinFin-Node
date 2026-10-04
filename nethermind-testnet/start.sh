#!/bin/bash

network="${NETWORK:-xdc-testnet}"
log_level="${NETHERMIND_LOG_LEVEL:-info}"
rpc_port="${RPC_PORT:-8505}"
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

# Testnet XDC nodes only accept the DK04 hub (--peers-allowlist), so peer with it directly
hub="enode://b3e242c2346557e8b4f7378bf17e0ad020046cd5e41be8e46d0148bfbd85cd36a9e3813f0bd7f34fcf6d5cd4d11bd375864f8d03aeaabb15d308238f2e55e4cb@38.143.58.165:30313"

args=(
    --config="${network}"
    --datadir=/nethermind/data
    --log="${log_level}"
    --JsonRpc.Enabled=true
    --JsonRpc.Host=0.0.0.0
    --JsonRpc.Port="${rpc_port}"
    --JsonRpc.EnabledModules=eth,xdc,debug
    --JsonRpc.JwtSecretFile=/tmp/jwt/jwtsecret
    --Network.DiscoveryPort=30306
    --Network.P2PPort=30306
    --Network.StaticPeers="${hub}"
    --HealthChecks.Enabled=true
    --Sync.SnapSync=false
    --Sync.PivotNumber=83600000
    --Sync.PivotHash=0x08491bba30cf8ef5bd269182f1d6aa1adbedc201a1a255c10f05dda913d2c2e5
    --Sync.PivotTotalDifficulty=339937235
    --Blocks.TargetBlockGasLimit=420000000
    --Db.EnableDbStatistics=true
    --Db.EnableMetricsUpdater=true
    --Db.StatsDumpPeriodSec=300
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
