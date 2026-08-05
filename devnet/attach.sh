#!/bin/bash
cd "$(dirname "$0")"
docker exec -it xdcnetwork-devnet-node XDC attach /work/xdcchain/XDC.ipc
