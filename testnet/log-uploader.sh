#!/bin/bash
# Renders fluent-bit.conf from template + .env on the host.
# The official fluent/fluent-bit image has no /bin/sh, so config must be
# generated before the container starts.
# Testnet identifies the node with NODE_NAME; that value is the Loki instance label.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f .env ]; then
    # shellcheck disable=SC1091
    set -a
    . ./.env
    set +a
fi

required_vars="LOKI_HOST NODE_NAME NETWORK"
for var in $required_vars; do
    if [ -z "${!var:-}" ]; then
        echo "Missing required environment variable: $var" >&2
        exit 1
    fi
done

LOKI_PORT="${LOKI_PORT:-3100}"
LOKI_URI="${LOKI_URI:-/loki/api/v1/push}"
LOKI_TLS="${LOKI_TLS:-off}"
LOKI_TLS_VERIFY="${LOKI_TLS_VERIFY:-on}"
NODE_VERSION="${NODE_VERSION:-unknown}"
NODE_COMMIT="${NODE_COMMIT:-unknown}"

# Loki label values cannot contain spaces/commas/quotes
for var in NODE_NAME NETWORK NODE_VERSION NODE_COMMIT; do
    val="${!var}"
    if [[ "$val" =~ [[:space:],\"\'=] ]]; then
        echo "Invalid characters in $var='$val' (no spaces/commas/quotes for Loki labels)" >&2
        exit 1
    fi
done

AUTH_FILE="$(mktemp)"
trap 'rm -f "$AUTH_FILE"' EXIT
: >"$AUTH_FILE"
if [ -n "${LOKI_USER:-}" ] || [ -n "${LOKI_PASSWORD:-}" ]; then
    if [ -z "${LOKI_USER:-}" ] || [ -z "${LOKI_PASSWORD:-}" ]; then
        echo "Both LOKI_USER and LOKI_PASSWORD must be set when using Loki auth" >&2
        exit 1
    fi
    printf '    http_user   %s\n    http_passwd %s\n' "$LOKI_USER" "$LOKI_PASSWORD" >"$AUTH_FILE"
fi

TMP_IN="$(mktemp)"
trap 'rm -f "$AUTH_FILE" "$TMP_IN"' EXIT

sed \
    -e "s|\${LOKI_HOST}|${LOKI_HOST}|g" \
    -e "s|\${LOKI_PORT}|${LOKI_PORT}|g" \
    -e "s|\${LOKI_URI}|${LOKI_URI}|g" \
    -e "s|\${LOKI_TLS_VERIFY}|${LOKI_TLS_VERIFY}|g" \
    -e "s|\${LOKI_TLS}|${LOKI_TLS}|g" \
    -e "s|\${INSTANCE_NAME}|${NODE_NAME}|g" \
    -e "s|\${NETWORK}|${NETWORK}|g" \
    -e "s|\${NODE_VERSION}|${NODE_VERSION}|g" \
    -e "s|\${NODE_COMMIT}|${NODE_COMMIT}|g" \
    fluent-bit.conf.template >"$TMP_IN"

OUT=fluent-bit.conf
: >"$OUT"
chmod 600 "$OUT"
while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        *'${LOKI_AUTH_BLOCK}'*)
            cat "$AUTH_FILE" >>"$OUT"
            ;;
        *)
            printf '%s\n' "$line" >>"$OUT"
            ;;
    esac
done <"$TMP_IN"

echo "Wrote $OUT → Loki ${LOKI_HOST}:${LOKI_PORT}${LOKI_URI} (tls=${LOKI_TLS})"
