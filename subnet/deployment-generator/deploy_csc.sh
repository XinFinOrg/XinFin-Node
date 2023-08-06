#!/bin/bash
cd "$(dirname "$0")"
scriptdir=$PWD
rm -r XDC-Subnet
git clone https://github.com/XinFinOrg/XDC-Subnet
cd XDC-Subnet/mainnet_contract
git checkout master && git pull 
cp "$scriptdir/config/deployment.json" deployment.json
echo "PRIVATE_KEY=$1" >> .env #a7f3b3dd62552eba8d22d1b8a81f14952065a6b275e12ecc4d8851b9b751d95f
yarn
npx hardhat run scripts/deployment.js --network xdcdevnet