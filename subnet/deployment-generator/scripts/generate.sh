#!/bin/bash
VERSION_GENERATOR="v1.0.0"
VERSION_GENESIS="v0.3.1"

current_dir="$(cd "$(dirname "$0")" && pwd)"

echo 'pull docker images'
docker pull xinfinorg/subnet-generator:$VERSION_GENERATOR
docker pull xinfinorg/xdcsubnets:$VERSION_GENESIS


echo ''
echo 'go to http://localhost:5210 to access Subnet Configuration Generator UI'
echo 'or use ssh tunnel if this is running on your server'
echo 'ssh -N -L localhost:5210:localhost:5210 <username>@<ip_address> -i <private_key_file>'
mkdir -p generated/scripts
docker run -p 5210:5210 -v $current_dir/generated:/app/generated xinfinorg/subnet-generator:$VERSION_GENERATOR


echo 'generating genesis.json'
docker run -v $current_dir/generated/:/app/generated/ --entrypoint 'bash' xinfinorg/xdcsubnets:$VERSION_GENESIS /work/puppeth.sh || pup_success=false
if [[ $pup_success == false ]]; then
  echo 'genesis.json generation failed'
  exit 1
fi

echo 'subnet generation successful'
