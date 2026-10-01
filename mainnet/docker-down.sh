#!/bin/bash

set -euo pipefail

if [ -f .env ]; then
    # shellcheck disable=SC1091
    . ./.env
fi

compose_args=(-f docker-compose.yml)
if [ "${ENABLE_LOKI_LOGS:-false}" = "true" ]; then
    compose_args+=(--profile loki-logs)
fi

docker compose "${compose_args[@]}" down
