#!/bin/bash

# Prefer the modern Docker Compose (v2 plugin)
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
else
    COMPOSE="docker-compose"
    echo "Using legacy docker-compose. Upgrade to docker compose is recommended."
fi

# Now run compose
$COMPOSE -f docker-compose.yml up -d --build --force-recreate
