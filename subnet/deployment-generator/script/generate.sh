#!/bin/bash
VERSION_GENERATOR="latest"
VERSION_CSC="v0.1.1"
VERSION_SUBNET="v0.2.2"

current_dir="$(cd "$(dirname "$0")" && pwd)"
echo 'checking for docker.env'
if [ ! -f "docker.env" ]; then
  echo 'docker.env not found'
  exit 1
fi

if ! grep -q "CONFIG_PATH" "docker.env"; then
  line="#current directory"$'\n'"CONFIG_PATH=$(pwd)"
  echo "$line" | cat - "docker.env" > temp && mv temp "docker.env"
  echo 'added CONFIG_PATH to docker.env'
fi

echo 'pull docker images'
docker pull xinfinorg/subnet-generator:$VERSION_GENERATOR
docker pull xinfinorg/csc:$VERSION_CSC
docker pull xinfinorg/xdcsubnets:$VERSION_SUBNET

echo ''
echo 'generating configs'
mkdir -p generated
docker run --env-file docker.env -v $current_dir/generated:/app/generated xinfinorg/subnet-generator:$VERSION_GENERATOR || gen_success=false
if [[ $gen_success == false ]]; then
  echo 'configs generation failed'
  exit 1
fi

echo 'generating genesis.json'
docker run -v $current_dir/generated/:/app/generated/ --entrypoint 'bash' xinfinorg/xdcsubnets:$VERSION_SUBNET /work/puppeth.sh || pup_success=false
if [[ $pup_success == false ]]; then
  echo 'genesis.json generation failed'
  exit 1
fi

echo 'subnet generation successful'