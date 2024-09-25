#!/bin/bash
VERSION_GENERATOR="generator-ui-concept"

cd "$(dirname "$0")"
cd ..

read -p "Input Grandmaster PK (or any source wallet with funds): " SOURCE_PK
read -p "Input destination wallet address: " DEST_ADDR
read -p "Input transfer amount: " AMOUNT

extra=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  extra="--network generated_docker_net"
fi

docker pull xinfinorg/subnet-generator:$VERSION_GENERATOR
docker run --env-file common.env --entrypoint node $extra xinfinorg/subnet-generator:$VERSION_GENERATOR /app/src/faucet.js $SOURCE_PK $DEST_ADDR $AMOUNT