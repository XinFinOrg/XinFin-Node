#!/bin/bash

cd "$(dirname "$0")"


which docker-compose
if [[ $? != 0 ]]; then
    shopt -s expand_aliases
    alias docker-compose='docker compose'
fi

docker-compose down devnet1

