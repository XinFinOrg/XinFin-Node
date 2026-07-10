#!/bin/bash

RPC_URL="${RPC_URL:-https://devnetstats.hashlabs.apothem.network/rpc2/}"

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

# Step 2: Parse epoch number
current_epoch=$(echo "$epoch_response" | jq -r '.result.Epoch')

if [ -z "$current_epoch" ] || [ "$current_epoch" = "null" ]; then
    echo "Error: Could not parse epoch from response"
    echo "Response: $epoch_response"
    exit 1
fi

echo "Current epoch: $current_epoch" >&2

# Step 3: Get block info by epoch number
block_info_response=$(curl -s -X POST "$RPC_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"XDPoS_getBlockInfoByV2EpochNum\",
    \"params\": [$current_epoch],
    \"id\": 1
  }")

# Check for RPC error
error=$(echo "$block_info_response" | jq -r '.error // empty')
if [ -n "$error" ]; then
    echo "Error from XDPoS_getBlockInfoByV2EpochNum: $error"
    exit 1
fi

# Step 4: Parse block number, hash, and state root
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

echo ""

# Output in the requested format
cat << EOF
FASTSYNC_PIVOT_NUMBER=$block_number
FASTSYNC_PIVOT_HASH=$block_hash
FASTSYNC_PIVOT_ROOT=$state_root
EOF