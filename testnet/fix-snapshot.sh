#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
container_name="xdcnetwork-testnet-node"
list="snapshots.list"

if [[ ! -s "$list" ]]; then
    echo "Missing $list, generate it on DK04 with ./export-snapshot.sh > $list" >&2
    exit 1
fi

image=$(docker inspect -f '{{.Config.Image}}' "$container_name")
datadir="$PWD/xdcchain-testnet"

docker stop -t 120 "$container_name"

while read -r key value; do
    [[ -z "$key" ]] && continue
    docker run --rm --network none -v "${datadir}:/work/xdcchain" --entrypoint XDC "$image" \
        db put --datadir /work/xdcchain "$key" "$value"
done <"$list"

./docker-up.sh

for _ in $(seq 1 60); do
    sleep 5
    block=$(docker exec "$container_name" XDC attach --exec "eth.blockNumber" /work/xdcchain/XDC.ipc 2>/dev/null || true)
    echo "block: ${block:-starting}"
    [[ "$block" == "83599999" ]] && exit 0
done
echo "Did not reach 83599999 within 5 minutes, check the logs" >&2
exit 1
