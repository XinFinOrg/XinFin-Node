#!/bin/bash
cd /app/contract
remove0x=${PARENTCHAIN_WALLET_PK:2}
echo "PRIVATE_KEY=${remove0x}" >> .env 
cp /app/generated/deployment.config.json /app/contract/deployment.config.json
echo "RELAYER_MODE=${RELAYER_MODE}"
if [[ $RELAYER_MODE == 'full' ]]
then
  echo "Deploying full CSC"
  npx hardhat run /app/contract/scripts/FullCheckpointDeploy.js --network xdcparentnet 2>&1 | tee csc.log
elif [[ $RELAYER_MODE == 'lite' ]]
then
  echo "Deploying lite CSC"
  npx hardhat run /app/contract/scripts/LiteCheckpointDeploy.js --network xdcparentnet 2>&1 | tee csc.log
else
  echo "Unknown RELAYER_MODE"
  exit 1
fi

line=$(tail -n 1 csc.log)
echo $line
found=$(echo $line | grep "deployed to")
echo $found

if [[ $found == '' ]]
then
  echo 'CSC deployment failed'
  exit 1
else
  echo 'Replacing CSC address in common.env file'
  contract=${found: -42}
  echo $contract
  cat /app/generated/common.env | sed -e "s/CHECKPOINT_CONTRACT.*/CHECKPOINT_CONTRACT=$contract/" > temp.env
  mv temp.env /app/generated/common.env
fi