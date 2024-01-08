#!/bin/bash
VERSION_GENERATOR="generator-csc"
VERSION_CSC="generator-update"
VERSION_SUBNET="feature-puppeth-docker-2"

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

echo 'checking docker images'
if [[ -z "$(docker images -q xinfinorg/subnet-generator:$VERSION_GENERATOR)" ]]; then # || echo "doesn't exist"
  docker pull xinfinorg/subnet-generator:$VERSION_GENERATOR
fi
if [[ -z "$(docker images -q xinfinorg/csc:$VERSION_CSC)" ]]; then # || echo "doesn't exist"
  docker pull xinfinorg/csc:$VERSION_CSC
fi
if [[ -z "$(docker images -q xinfinorg/xdcsubnets:$VERSION_SUBNET)" ]]; then # || echo "doesn't exist"
  docker pull xinfinorg/xdcsubnets:$VERSION_SUBNET
fi

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