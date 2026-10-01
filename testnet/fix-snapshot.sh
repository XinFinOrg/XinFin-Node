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
head=$(docker exec "$container_name" XDC attach --exec "eth.blockNumber" /work/xdcchain/XDC.ipc)
echo "current block: $head"

docker stop -t 120 "$container_name"

while read -r key value; do
    [[ -z "$key" ]] && continue
    docker run --rm --network none -v "${datadir}:/work/xdcchain" --entrypoint XDC "$image" \
        db put --datadir /work/xdcchain "$key" "$value"
done <"$list"

[[ "$head" -lt 83599997 ]] && for key in \
    0x620000000004fba27d3f4ca3575dd5308ed566c9f47c445a23541ddfce7e63203324e469b8f109cfb8 \
    0x620000000004fba27e153bd922f9d18311eaf8ae0781b2bcf0d55f8339a64302e5d8614b496b18ff8c \
    0x620000000004fba27fdcd5e66dd062cfcfc4a4a5eb69fb6470ae600063d01293851ac8eade8ad79c7c; do
    docker run --rm --network none -v "${datadir}:/work/xdcchain" --entrypoint XDC "$image" \
        db delete --datadir /work/xdcchain "$key" || true
done

./docker-up.sh

for _ in $(seq 1 60); do
    sleep 5
    block=$(docker exec "$container_name" XDC attach --exec "eth.blockNumber" /work/xdcchain/XDC.ipc 2>/dev/null || true)
    echo "block: ${block:-starting}"
    [[ "$block" == "83599999" ]] && exit 0
done
echo "Did not reach 83599999 within 5 minutes, check the logs" >&2
exit 1
