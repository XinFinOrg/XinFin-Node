#!/bin/bash
apt update
apt upgrade
apt install nodejs20
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
apt install net-tools

#install docker compose V2
sudo apt-get update
sudo apt-get install docker-compose-plugin

#node 20
npm install
npm install -g yarn


