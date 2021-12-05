#!/bin/bash

echo "Upgrading XinFin Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfinnetwork:1.4.3_Fix_AddressPrefix
sudo docker-compose -f docker-services.yml down
git pull
sudo docker-compose -f docker-services.yml up -d

