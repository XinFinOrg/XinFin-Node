#!/bin/bash
cd "$(dirname "$0")"
if [ ! -d "XDC-Subnet" ]; then
  git clone https://github.com/XinFinOrg/XDC-Subnet
fi
if [ -z "$1" ]
  then
    branch=master
  else
    branch=$1
fi
cd XDC-Subnet
echo "building from $branch"
git checkout $branch && git pull && docker build -t localbuild-subnet -f docker/Dockerfile .
