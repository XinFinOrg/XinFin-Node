#!/bin/bash

HOSTIP=$(curl https://checkip.amazonaws.com) docker compose -f docker-compose.yml down
