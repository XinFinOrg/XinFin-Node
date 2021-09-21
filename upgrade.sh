#!/bin/bash

echo "Upgrading XinFin Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfinnetwork:evm_upgrade_apothem
sudo docker-compose -f apothem-network.yml restart

