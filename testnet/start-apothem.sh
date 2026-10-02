#!/bin/bash

if [ ! -d /work/xdcchain/XDC/chaindata ]; then
    wallet=$(XDC account new --password /work/.pwd --datadir /work/xdcchain | awk -F '[{}]' '{print $2}')
    echo "Initializing Testnet Genesis Block"
    echo "wallet: $wallet"
    coinbaseaddr="$wallet"
    coinbasefile=/work/xdcchain/coinbase.txt
    touch $coinbasefile
    if [ -f "$coinbasefile" ]; then
        echo "$coinbaseaddr" >"$coinbasefile"
        cat xdcchain/keystore/* >>"$coinbasefile"
    fi
    XDC init --datadir /work/xdcchain /work/genesis.json
else
    wallet=$(XDC account list --datadir /work/xdcchain | head -n 1 | awk -F '[{}]' '{print $2}')
    echo "wallet: $wallet"
fi

input="/work/bootnodes.list"
bootnodes=""
while IFS= read -r line; do
    if [ -z "${bootnodes}" ]; then
        bootnodes=$line
    else
        bootnodes="${bootnodes},$line"
    fi
done <"$input"

log_level=2
if test -z "$LOG_LEVEL"
then
  echo "Log level not set, default to verbosity of $log_level"
else
  echo "Log level found, set to $LOG_LEVEL"
  log_level=$LOG_LEVEL
fi

# create log file with timestamp
DATE="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/work/xdcchain/xdc-${DATE}.log"

sync_mode="${SYNC_MODE:-full}"
echo "Sync mode: $sync_mode"

# Build pivot args for fast sync
pivot_args=()
if [[ "${sync_mode}" == "fast" ]]; then
    if [[ -z "${FASTSYNC_PIVOT_NUMBER}" || -z "${FASTSYNC_PIVOT_HASH}" || -z "${FASTSYNC_PIVOT_ROOT}" ]]; then
        echo "ERROR: SYNC_MODE=fast requires FASTSYNC_PIVOT_NUMBER, FASTSYNC_PIVOT_HASH, and FASTSYNC_PIVOT_ROOT to be set."
        exit 1
    fi
    pivot_args=(
        --fastsyncpivotnumber "${FASTSYNC_PIVOT_NUMBER}"
        --fastsyncpivothash "${FASTSYNC_PIVOT_HASH}"
        --fastsyncpivotroot "${FASTSYNC_PIVOT_ROOT}"
    )
fi

# Set store_reward from STORE_REWARD env or default to 'false'
store_reward=false
if test -z "$STORE_REWARD"; then
    echo "STORE_REWARD not set, default to false"
else
    echo "STORE_REWARD found, set to $STORE_REWARD"
    store_reward=$STORE_REWARD
fi

# Set gc_mode from GC_MODE env or default to 'archive'
gc_mode=archive
if test -z "$GC_MODE"; then
    echo "GC_MODE not set, default to archive" # full or archive
else
    echo "GC_MODE found, set to $GC_MODE"
    gc_mode=$GC_MODE
fi

# Set chain_config_mismatch_policy from CHAIN_CONFIG_MISMATCH_POLICY env or default to 'update-config-only'
chain_config_mismatch_policy=update-config-only
if test -z "$CHAIN_CONFIG_MISMATCH_POLICY"; then
    echo "CHAIN_CONFIG_MISMATCH_POLICY not set, default to update-config-only" # exit, rewind-and-update, update-config-only or ignore-mismatch
else
    echo "CHAIN_CONFIG_MISMATCH_POLICY found, set to $CHAIN_CONFIG_MISMATCH_POLICY"
    chain_config_mismatch_policy=$CHAIN_CONFIG_MISMATCH_POLICY
fi

INSTANCE_IP=$(curl https://checkip.amazonaws.com)
netstats="${NODE_NAME}:xdc_xinfin_apothem_network_stats@stats.apothem.network:2000"

peers=(
    "enode://b3e242c2346557e8b4f7378bf17e0ad020046cd5e41be8e46d0148bfbd85cd36a9e3813f0bd7f34fcf6d5cd4d11bd375864f8d03aeaabb15d308238f2e55e4cb@38.143.58.165:30313"
    "enode://c33534023348ac28529368b133fba9131fe3e3cf23ce2529377b14f5cf602bd8f30f718e35f24c9cfeabc296e55d84d34b438d91094d756f69483a0957e0e051@38.102.87.241:30312"
    "enode://4d805a0032e9298d9ba1b10dd51327f1d2d976d456ff13d523ed43a22dd27fc54d834ab5fd9c5e0067b379609d72dd3205776c3b94e881cfd610cd1e4432115f@152.114.194.209:30312"
    "enode://6cf6f61adc18e73af5e7727e12425f9320ed3c67be04c8a5deb18ed1cf10bcd1c73c6b62c7306071ac7f1a05d6214388084b4d3ffa0ac4a17fbae473faffd008@158.255.0.115:30312"
    "enode://9724b9cff3ae4286d13b29d2e13c1db0a3ce8ed1d469b945b4f626edf42d4043375be474bf94abd9065c52a840e207a26d6c4a86de87263d1cf0f8af561d1c2a@104.152.209.185:30312"
    "enode://f6df90379e5abc520a07f2dd9cabb8d43cc5a2812e648b20a4339b61942e1ab74062a26e9126898b59fc86961f49c599bbab426bf2805e41a9d6112c2e7b521b@207.90.192.35:30312"
    "enode://54d4cfde7b548f4e3ab5154e62357ed6ebdb57f81abd678f2a0abc5d1058b3dbea069f872dc9f62154db90ba3ca1a16d338efc15e90c688a8afccd41e99f91ff@208.98.38.230:30312"
    "enode://c68cec795fa38cd70b99c4c25cb783565de6446a30fb365afe85d86d870e7badf32370e04b06d76107f02957871f280f5acbb56acc8cf44ea914a0c019d71e12@38.102.86.183:30312"
    "enode://729d763db071595bacbbf33037a8e7639d8e9a97bfcfcda3afe963435d919cb95634f27375f0aadf6494dad47e506c888bf15cb5633d5f81dbb793b05b27e676@158.255.0.178:30312"
    "enode://f839de27dfbe0c5254d47c14974dc65ec66f00bd0cda2ebf63443f498e9d871980c1776cb75871dfa670bfb46f016471741b345db2bb30d2f974de33591e7d05@209.145.55.3:30312"
    "enode://0cf2a4c52cead0ebc6ae26ef51e58f9c09773c54c1d6620fb8681f29d7ddd34c8ce40d64f39cbb9b210ce9f8ef27be7bdbf48b187e8279ae5ce863b111bcb341@38.102.124.216:30312"
)
peers_toml=$(printf '"%s", ' "${peers[@]}")
peers_toml="[${peers_toml%, }]"
peers_csv=$(IFS=,; echo "${peers[*]}")
cat >/work/xdcchain/p2p.toml <<EOF
[Node.P2P]
StaticNodes = ${peers_toml}
TrustedNodes = ${peers_toml}
EOF

echo "Starting nodes with $bootnodes ..."
args=(
    --ethstats "${netstats}"
    --bootnodes "${bootnodes}"
    --syncmode "${sync_mode}"
    --gcmode "${gc_mode}"
    --chain-config-mismatch-policy "${chain_config_mismatch_policy}"
    --datadir /work/xdcchain
    --XDCx.datadir /work/xdcchain/XDCx
    --networkid 51
    --port 30312
    --config /work/xdcchain/p2p.toml
    --nodiscover
    --peers-allowlist "${peers_csv}"
    --unlock "${wallet}"
    --password /work/.pwd
    --mine
    --gasprice "1"
    --targetgaslimit "420000000"
    --verbosity "${log_level}"
)

if [[ "${store_reward}" == "true" ]]; then
    args+=(--store-reward)
fi

if [[ ${#pivot_args[@]} -gt 0 ]]; then
    args+=("${pivot_args[@]}")
fi

# RPC and WebSocket configuration - exact match required for security
if [[ "${ENABLE_RPC}" == "true" ]]; then
    args+=(
        --http
        --http-addr "0.0.0.0"
        --http-port "${RPC_PORT}"
        --http-api "${API}"
        --http-corsdomain "${ALLOWED_ORIGINS}"
        --http-vhosts "${RPC_VHOSTS}"
    )
else
    # When not "true", explicitly disable RPC to avoid unintended exposure
    args+=(
        --http=false
    )
fi

if [[ "${ENABLE_WS}" == "true" ]]; then
    args+=(
        --ws
        --ws-addr "0.0.0.0"
        --ws-port "${WS_PORT}"
        --ws-api "${API}"
        --ws-origins "${ALLOWED_ORIGINS}"
    )
else
    # When not "true", explicitly disable WebSocket to avoid unintended exposure
    args+=(
        --ws=false
    )
fi

XDC "${args[@]}" 2>&1 >>"${LOG_FILE}" | tee -a "${LOG_FILE}"
