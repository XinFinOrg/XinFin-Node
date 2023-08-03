#!/bin/bash
sudo apt-get update
sudo apt-get install docker-compose-plugin

docker compose pull

npm install -g yarn