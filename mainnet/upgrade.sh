#!/bin/bash

echo "Upgrading XDC Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfinnetwork:v1.4.6
sudo docker-compose -f docker-compose.yml down
git pull
sudo docker-compose -f docker-compose.yml up -d

