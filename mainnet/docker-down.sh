#!/bin/bash

set -euo pipefail

if [ -f .env ]; then
    # shellcheck disable=SC1091
    . ./.env
fi

compose_args=(-f docker-compose.yml)
if [ "${ENABLE_S3_LOGS:-false}" = "true" ]; then
    compose_args+=(--profile s3-logs)
fi

docker compose "${compose_args[@]}" down
