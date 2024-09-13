#!/bin/bash
VERSION_GENERATOR="generator-ui-concept"

cd "$(dirname "$0")"
cd ..

read -p "Input Grandmaster PK (or any source wallet with funds): " SOURCE_PK

extra=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  extra="--network generated_docker_net"
fi

docker pull xinfinorg/subnet-generator:$VERSION_GENERATOR
docker run --env-file common.env --entrypoint node -p 5211:5211 $extra xinfinorg/subnet-generator:$VERSION_GENERATOR /app/src/faucet.js server $SOURCE_PK
