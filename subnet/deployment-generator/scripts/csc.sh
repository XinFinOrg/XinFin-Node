#!/bin/bash

cd "$(dirname "$0")"

if [[ -z $1 ]] || [[ -z $2 ]]; then
  echo "Missing argument"
  echo "Usage: csc.sh VERSION MODE"
  echo "Version: latest or check documentation for available versions"
  echo "Mode: lite, full, or reverse"
  exit
fi


docker pull xinfinorg/csc:$1
docker run --env-file ../contract_deploy.env --network generated_docker_net xinfinorg/csc:$1 $2

