#!/bin/bash

echo "Upgrading XinFin Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfinnetwork:xdc_mainnet_ignoreBlock
sudo docker-compose -f docker-services.yml down
sudo docker-compose -f docker-services.yml up -d

