#!/bin/bash

#node 20
sudo apt-get update
sudo apt-get upgrade
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &&\
sudo apt-get install -y nodejs

#install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

#install docker compose V2
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install docker-compose-plugin

#extra debug tools
apt-get install net-tools

#install dependencies
npm install
npm install -g yarn