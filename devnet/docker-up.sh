#!/bin/bash

which docker-compose

if [[ $? != 0 ]]; then
    shopt -s expand_aliases
    alias docker-compose='docker compose'
fi

HOSTIP=$(curl https://checkip.amazonaws.com) docker-compose -f docker-compose.yml up -d
