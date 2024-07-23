#!/bin/bash

which docker-compose

if [[ $? != 0 ]]; then
    shopt -s expand_aliases
    alias docker-compose='docker compose'
fi

docker-compose -f docker-compose.yml up -d --build --force-recreate
