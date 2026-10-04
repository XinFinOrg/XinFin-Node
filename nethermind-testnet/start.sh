#!/bin/bash

network="${NETWORK:-xdc-testnet}"
log_level="${NETHERMIND_LOG_LEVEL:-info}"
rpc_port="${RPC_PORT:-8505}"
rpc_modules="${RPC_MODULES:-Eth,Net,Web3,Xdc,Health}"
echo "Network: $network, log level: $log_level, RPC port: $rpc_port, RPC modules: $rpc_modules"

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

# Sync mode: fast (default, from a pivot block) or full (executes every block from genesis)
sync_mode="${SYNC_MODE:-fast}"
echo "Sync mode: $sync_mode"
sync_args=()
case "$sync_mode" in
    fast)
        sync_args+=(--Sync.FastSync=true)
        pivot_number="${FASTSYNC_PIVOT_NUMBER}"
        pivot_hash="${FASTSYNC_PIVOT_HASH}"
        pivot_td="${FASTSYNC_PIVOT_TOTAL_DIFFICULTY}"
        if [[ -n "${pivot_number}${pivot_hash}${pivot_td}" ]]; then
            if [[ -z "${pivot_number}" || -z "${pivot_hash}" || -z "${pivot_td}" ]]; then
                echo "ERROR: a custom pivot needs FASTSYNC_PIVOT_NUMBER, FASTSYNC_PIVOT_HASH and FASTSYNC_PIVOT_TOTAL_DIFFICULTY all set."
                exit 1
            fi
            echo "Pivot: ${pivot_number} ${pivot_hash}"
            sync_args+=(
                --Sync.PivotNumber="${pivot_number}"
                --Sync.PivotHash="${pivot_hash}"
                --Sync.PivotTotalDifficulty="${pivot_td}"
            )
        else
            echo "Pivot: using the image's built-in pivot"
        fi
        ;;
    full)
        sync_args+=(--Sync.FastSync=false)
        ;;
    *)
        echo "ERROR: SYNC_MODE must be 'fast' or 'full', got '${sync_mode}'"
        exit 1
        ;;
esac

# GC mode: full (default, prunes old state) or archive (keeps all state from where the sync starts)
gc_mode="${GC_MODE:-full}"
echo "GC mode: $gc_mode"
case "$gc_mode" in
    full) pruning_mode=Hybrid ;;
    archive) pruning_mode=None ;;
    *)
        echo "ERROR: GC_MODE must be 'full' or 'archive', got '${gc_mode}'"
        exit 1
        ;;
esac

args=(
    --config="${network}"
    --datadir=/nethermind/data
    --log="${log_level}"
    --JsonRpc.Enabled=true
    --JsonRpc.Host=0.0.0.0
    --JsonRpc.Port="${rpc_port}"
    --JsonRpc.EnabledModules="${rpc_modules}"
    --JsonRpc.JwtSecretFile=/tmp/jwt/jwtsecret
    --Network.DiscoveryPort=30306
    --Network.P2PPort=30306
    --Network.StaticPeers="${hub}"
    --HealthChecks.Enabled=true
    "${sync_args[@]}"
    --Pruning.Mode="${pruning_mode}"
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
