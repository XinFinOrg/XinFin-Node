#!/bin/bash

# Computes the fast-sync pivot point for a given XDC network.
#
# Usage: ./get_pivot_for_fast_sync.sh [mainnet|testnet]
#
# The network may also be given via the NETWORK env var; it defaults to mainnet.
# RPC_URL overrides the network's default endpoint.

network="${1:-${NETWORK:-mainnet}}"

# Per-network epoch, switchEpoch and default RPC endpoint
case "$network" in
    mainnet)
        epoch=900
        switchEpoch=89300
        default_rpc="https://erpc.xinfin.network"
        ;;
    testnet)
        epoch=900
        switchEpoch=63143
        default_rpc="https://earpc.apothem.network"
        ;;
    *)
        echo "Error: unknown network '$network' (expected 'mainnet' or 'testnet')"
        exit 1
        ;;
esac

# RPC endpoint (can be overridden with env var)
RPC_URL="${RPC_URL:-$default_rpc}"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq."
    exit 1
fi

# Wrapper around curl for a single JSON-RPC call. Fails fast on transport and
# HTTP errors, and on a JSON-RPC error object in the response body.
rpc_call() {
    local method="$1" params="$2" response error

    response=$(curl -s --fail --connect-timeout 10 --max-time 30 --retry 2 -X POST "$RPC_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"$method\",
        \"params\": $params,
        \"id\": 1
      }") || { echo "Error: request to $RPC_URL failed ($method)" >&2; return 1; }

    error=$(echo "$response" | jq -r '.error // empty')
    if [ -n "$error" ]; then
        echo "Error from $method: $error" >&2
        return 1
    fi

    printf '%s' "$response"
}

# Step 1: Get current epoch number from masternodes
epoch_response=$(rpc_call "XDPoS_getMasternodesByNumber" '["latest"]') || exit 1

# 1. Parse current_round from $epoch_response
current_round=$(echo "$epoch_response" | jq -r '.result.Round')
if [ -z "$current_round" ] || [ "$current_round" = "null" ]; then
    echo "Error: Could not parse round from response"
    echo "Response: $epoch_response"
    exit 1
fi

# 2. Calculate current_epoch = floor(current_round/epoch) + switchEpoch
# Using jq 'floor' for integer division
current_epoch=$(jq -n \
    --arg round "$current_round" \
    --arg epoch "$epoch" \
    --arg switch "$switchEpoch" \
    '(($round | tonumber) / ($epoch | tonumber) | floor) + ($switch | tonumber)')

# Step 2: Get block info by epoch number
block_info_response=$(rpc_call "XDPoS_getBlockInfoByEpochNum" "[$current_epoch]") || exit 1

# Step 3: Parse block number, hash, and state root
block_number=$(echo "$block_info_response" | jq -r '.result.firstBlock')
block_hash=$(echo "$block_info_response" | jq -r '.result.hash')

if [ -z "$block_number" ] || [ "$block_number" = "null" ]; then
    echo "Error: Could not parse block number from response"
    echo "Response: $block_info_response"
    exit 1
fi

if [ -z "$block_hash" ] || [ "$block_hash" = "null" ]; then
    echo "Error: Could not parse block hash from response"
    echo "Response: $block_info_response"
    exit 1
fi

# State root needs to be fetched separately using eth_getBlockByHash
block_details=$(rpc_call "eth_getBlockByHash" "[\"$block_hash\", false]") || exit 1

state_root=$(echo "$block_details" | jq -r '.result.stateRoot')

if [ -z "$state_root" ] || [ "$state_root" = "null" ]; then
    echo "Error: Could not parse state root from response"
    echo "Response: $block_details"
    exit 1
fi

# Output in the requested format
cat << EOF
FASTSYNC_PIVOT_NUMBER=$block_number
FASTSYNC_PIVOT_HASH=$block_hash
FASTSYNC_PIVOT_ROOT=$state_root
EOF
