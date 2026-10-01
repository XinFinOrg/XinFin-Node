#!/usr/bin/env bash
# POST this node's deployment to the AIOps API once at startup.
# Called from docker-up.sh when AIOPS_SERVICE_URL is set.
#
# Required:
#   AIOPS_SERVICE_URL  e.g. https://aiops.devnet.xinfin.org
#
# Optional:
#   DEPLOY_NOTES   free-text note
#   DEPLOYED_BY    default: $USER
#   DRY_RUN=1      print JSON only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a
  . ./.env
  set +a
fi

DRY_RUN="${DRY_RUN:-0}"
DEPLOYED_BY="${DEPLOYED_BY:-${USER:-xinfin-node}}"
DEPLOY_NOTES="${DEPLOY_NOTES:-}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

if [[ -z "${AIOPS_SERVICE_URL:-}" && "$DRY_RUN" != "1" ]]; then
  echo "ERROR: AIOPS_SERVICE_URL is required (or set DRY_RUN=1)" >&2
  exit 1
fi

for var in NODE_NAME NETWORK; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: $var is required in .env" >&2
    exit 1
  fi
done

NODE_VERSION="${NODE_VERSION:-unknown}"
NODE_COMMIT="${NODE_COMMIT:-unknown}"

IMAGE_REF="$(grep -E '^\s+image:\s+' "$COMPOSE_FILE" | head -1 | awk '{print $2}')"
if [[ -z "$IMAGE_REF" ]]; then
  echo "ERROR: could not parse image from $COMPOSE_FILE" >&2
  exit 1
fi

IMAGE="${IMAGE_REF%:*}"
IMAGE_TAG="${IMAGE_REF##*:}"
if [[ "$IMAGE_TAG" == "$IMAGE_REF" ]]; then
  IMAGE_TAG="latest"
fi

GIT_COMMIT="$NODE_COMMIT"
GIT_TAG="$NODE_VERSION"
if [[ "$GIT_COMMIT" == "unknown" && "$IMAGE_TAG" =~ ([0-9a-f]{7,40})$ ]]; then
  GIT_COMMIT="${BASH_REMATCH[1]}"
fi
if [[ "$GIT_TAG" == "unknown" ]]; then
  GIT_TAG="$IMAGE_TAG"
fi

COINBASE=""
if [[ -f xdcchain-testnet/coinbase.txt ]]; then
  COINBASE="$(tr -d '[:space:]' < xdcchain-testnet/coinbase.txt)"
fi

HOST_NICKNAME="$(hostname -s 2>/dev/null || hostname)"
DEPLOYED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

PAYLOAD="$(
  NETWORK="$NETWORK" \
  NODE_NAME="$NODE_NAME" \
  COINBASE="$COINBASE" \
  IMAGE="$IMAGE" \
  IMAGE_TAG="$IMAGE_TAG" \
  GIT_COMMIT="$GIT_COMMIT" \
  GIT_TAG="$GIT_TAG" \
  HOST_NICKNAME="$HOST_NICKNAME" \
  DEPLOYED_BY="$DEPLOYED_BY" \
  DEPLOY_NOTES="$DEPLOY_NOTES" \
  DEPLOYED_AT="$DEPLOYED_AT" \
  python3 - <<'PY'
import json, os

def none_if_blank(s):
    s = (s or "").strip()
    return s or None

print(json.dumps({
    "network": os.environ["NETWORK"],
    "node_name": os.environ["NODE_NAME"],
    "image": os.environ["IMAGE"],
    "image_tag": os.environ["IMAGE_TAG"],
    "git_commit": none_if_blank(os.environ.get("GIT_COMMIT")),
    "git_tag": none_if_blank(os.environ.get("GIT_TAG")),
    "coinbase": none_if_blank(os.environ.get("COINBASE")),
    "host_nickname": none_if_blank(os.environ.get("HOST_NICKNAME")),
    "deployed_by": none_if_blank(os.environ.get("DEPLOYED_BY")),
    "notes": none_if_blank(os.environ.get("DEPLOY_NOTES")),
    "deployed_at": os.environ["DEPLOYED_AT"],
}))
PY
)"

echo "==> record deployment"
echo "    $PAYLOAD"

if [[ "$DRY_RUN" == "1" ]]; then
  exit 0
fi

URL="${AIOPS_SERVICE_URL%/}/api/deployments"
echo "==> POST $URL"

HTTP_CODE="$(
  curl -sS -o /tmp/aiops-deploy-resp.txt -w '%{http_code}' \
    -X POST "$URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD"
)"

if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
  echo "ERROR: AIOps returned HTTP $HTTP_CODE" >&2
  cat /tmp/aiops-deploy-resp.txt >&2 || true
  echo >&2
  exit 1
fi

echo "==> recorded OK (HTTP $HTTP_CODE)"
cat /tmp/aiops-deploy-resp.txt
echo
