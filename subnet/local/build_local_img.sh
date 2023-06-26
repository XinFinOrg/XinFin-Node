#!/bin/bash
cd "$(dirname "$0")"
git clone https://github.com/XinFinOrg/XDC-Subnet
cd XDC-Subnet
# git checkout penalty-at-gap-block-update
git checkout master && git pull && docker build -t localbuild-subnet -f docker/Dockerfile .
