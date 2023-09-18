#!/bin/sh
echo "Upgrading XDC Network Configuration Scripts"
cd testnet
mv .env .env_tmp

git stash
git pull

source .env_tmp
sed -i "s/NODE_NAME=XF_MasterNode/NODE_NAME=$NODE_NAME/" .env
sed -i "s/CONTACT_DETAILS=YOUR_EMAIL_ADDRESS/CONTACT_DETAILS=$CONTACT_DETAILS/" .env
sed -i "s/NODE_TYPE=full/NODE_TYPE=$NODE_TYPE/" .env

bash docker-down.sh
mv xdcchain xdcchain-testnet || true
mv start.sh start-apothem.sh || true
bash docker-up.sh