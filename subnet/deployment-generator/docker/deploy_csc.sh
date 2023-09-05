#!/bin/bash
cd /app/contract
remove0x=${PARENTCHAIN_WALLET_PK:2}
echo "PRIVATE_KEY=${remove0x}" >> .env 
cp /app/generated/deployment.config.json /app/contract/deployment.config.json
echo "RELAYER_MODE=${RELAYER_MODE}"
if [[ $RELAYER_MODE == 'full' ]]
then
  echo "Deploying full CSC"
  npx hardhat run /app/contract/scripts/FullCheckpointDeploy.js --network xdcparentnet
elif [[ $RELAYER_MODE == 'lite' ]]
then
  echo "Deploying lite CSC"
  npx hardhat run /app/contract/scripts/LiteCheckpointDeploy.js --network xdcparentnet
else
  echo "Unknown RELAYER_MODE"
fi
