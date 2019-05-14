#!/bin/bash

echo "Upgrading Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfin-testnet-node:networkid1151
