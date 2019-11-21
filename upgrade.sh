#!/bin/bash

echo "Upgrading XinFin Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfinnetwork:xdc_mainnet_v1.0.1
