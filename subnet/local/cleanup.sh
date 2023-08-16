#!/bin/bash
cd "$(dirname "$0")"

docker-compose down

rm -rf ./XDC-Subnet 
rm -r ./xdcchain* 
rm -r ./puppeth
rm -r ./bootnodes