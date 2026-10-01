#!/bin/bash
set -euo pipefail

container_name="xdcnetwork-testnet-node"
keys=(
    0x5844506f532d56322d947b99b4933283f5e12805fea821114054d796ceada117cdbab73208bc891e66
    0x5844506f532d56322d6759c616ed596754f8d26ac956dea415778b327b77fc9d69d07a747de2a74277
)

for key in "${keys[@]}"; do
    value=$(docker exec "$container_name" XDC attach --exec "debug.dbGet(\"${key}\")" /work/xdcchain/XDC.ipc | tr -d '"')
    if [[ "$value" != 0x* ]]; then
        echo "Failed to read ${key}: ${value}" >&2
        exit 1
    fi
    echo "${key} ${value}"
done
