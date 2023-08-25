#!/bin/bash
cd /app/contract
remove0x=${PARENTCHAIN_WALLET_PK:2}
echo "PRIVATE_KEY=${remove0x}" >> .env 
cp /app/generated/deployment.json /app/contract/deployment.json
npx hardhat run /app/contract/scripts/fullCheckpointDeploy.js --network xdcparentnet