#!/bin/bash

echo "Upgrading Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfin-testnet-node:1130199b95301c8696e1fc94eccb7e0549c8b262
sudo docker pull xinfinorg/netapis