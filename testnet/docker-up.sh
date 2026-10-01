#!/bin/bash

set -euo pipefail

if [ -f .env ]; then
    # shellcheck disable=SC1091
    . ./.env
fi

compose_args=(-f docker-compose.yml)
if [ "${ENABLE_LOKI_LOGS:-false}" = "true" ]; then
    ./log-uploader.sh
    compose_args+=(--profile loki-logs)
fi

docker compose "${compose_args[@]}" up -d --build --force-recreate

if [ -n "${AIOPS_SERVICE_URL:-}" ]; then
    chmod +x record-deployment.sh
    ./record-deployment.sh || echo "WARN: deployment not recorded" >&2
fi
