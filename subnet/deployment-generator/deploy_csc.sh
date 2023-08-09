#!/bin/bash
cd "$(dirname "$0")"
scriptdir=$PWD
rm -r XDC-Subnet
git clone https://github.com/XinFinOrg/XDC-Subnet
cd XDC-Subnet/mainnet_contract
git checkout master && git pull 
cp "$scriptdir/config/deployment.json" deployment.json
echo "PRIVATE_KEY=$1" >> .env 
yarn
npx hardhat run scripts/deployment.js --network xdcparentnet