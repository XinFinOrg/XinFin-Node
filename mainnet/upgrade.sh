#!/bin/bash

echo "Upgrading XDC Network Configuration Scripts"

mv .env .env.bak
mv .nodekey .nodekey.bak

git stash
git pull

mv .env.bak .env
mv .nodekey.bak .nodekey

echo "Upgrading Docker Images"
sudo docker pull xinfinorg/xdposchain:v2.4.2-hotfix
sudo docker-compose -f docker-compose.yml down
git pull
sudo docker-compose -f docker-compose.yml up -d
