#!/bin/bash

echo "Upgrading XinFin Network Configuration Scripts"
git pull
echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xinfinnetwork:1.4.3
sudo docker-compose -f docker-services.yml down
sudo docker-compose -f docker-services.yml up -d

