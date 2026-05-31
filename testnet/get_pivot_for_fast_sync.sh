#!/bin/bash

# RPC endpoint (can be overridden with env var)
RPC_URL="${RPC_URL:-https://earpc.apothem.network}"

# Epoch and switchEpoch for testnet
epoch=900
switchEpoch=63143

# Step 1: Get current epoch number from masternodes
epoch_response=$(curl -s -X POST "$RPC_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "XDPoS_getMasternodesByNumber",
    "params": ["latest"],
    "id": 1
  }')

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq."
    exit 1
fi

# Check for RPC error
error=$(echo "$epoch_response" | jq -r '.error // empty')
if [ -n "$error" ]; then
    echo "Error from XDPoS_getMasternodesByNumber: $error"
    exit 1
fi

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
block_info_response=$(curl -s -X POST "$RPC_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"XDPoS_getBlockInfoByEpochNum\",
    \"params\": [$current_epoch],
    \"id\": 1
  }")

# Check for RPC error
error=$(echo "$block_info_response" | jq -r '.error // empty')
if [ -n "$error" ]; then
    echo "Error from XDPoS_getBlockInfoByEpochNum: $error"
    exit 1
fi

# Step 3: Parse block number, hash, and state root
block_number=$(echo "$block_info_response" | jq -r '.result.firstBlock')
block_hash=$(echo "$block_info_response" | jq -r '.result.hash')

# State root needs to be fetched separately using eth_getBlockByHash
block_details=$(curl -s -X POST "$RPC_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_getBlockByHash\",
    \"params\": [\"$block_hash\", false],
    \"id\": 1
  }")

state_root=$(echo "$block_details" | jq -r '.result.stateRoot')

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

if [ -z "$state_root" ] || [ "$state_root" = "null" ]; then
    echo "Error: Could not parse state root from response"
    echo "Response: $block_details"
    exit 1
fi

# Output in the requested format
cat << EOF
SYNC_MODE=fast
FASTSYNC_PIVOT_NUMBER=$block_number
FASTSYNC_PIVOT_HASH=$block_hash
FASTSYNC_PIVOT_ROOT=$state_root
EOF
