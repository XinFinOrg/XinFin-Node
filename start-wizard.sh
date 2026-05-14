#!/usr/bin/env bash
# Interactive .env configuration wizard for XinFin Node.
# Usage: ./start-wizard.sh <mainnet|testnet>

set -o pipefail

# ── colours ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'

# ── usage ─────────────────────────────────────────────────────────────────────
usage() {
    printf "\n${BOLD}Usage:${NC} %s <mainnet|testnet>\n\n" "$0"
    exit 1
}

[ "${1:-}" = "" ] && usage
ENV_NAME="$1"
[ "$ENV_NAME" != "mainnet" ] && [ "$ENV_NAME" != "testnet" ] && {
    printf "${RED}Error:${NC} env must be 'mainnet' or 'testnet'\n"
    usage
}

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DIR="$REPO_ROOT/$ENV_NAME"
EXAMPLE="$DIR/env.example"
ENVFILE="$DIR/.env"

[ ! -f "$EXAMPLE" ] && { printf "${RED}Error:${NC} %s not found\n" "$EXAMPLE"; exit 1; }

# Temp file stores collected key=value pairs; cleaned up on exit
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# ── helpers ───────────────────────────────────────────────────────────────────

# Read a single key's value from a file
read_key() {
    grep -m1 "^${1}=" "$2" 2>/dev/null | cut -d'=' -f2- || true
}

# Effective current value: prefer .env, fall back to env.example
current_val() {
    local val=""
    [ -f "$ENVFILE" ] && val=$(read_key "$1" "$ENVFILE")
    [ -z "$val" ]     && val=$(read_key "$1" "$EXAMPLE")
    printf '%s' "$val"
}

# Retrieve a collected value from the temp file
collected_val() {
    read_key "$1" "$TMPFILE"
}

# One-line description for each known variable
desc_of() {
    case "$1" in
        INSTANCE_NAME)   printf 'Node name shown on stats.xinfin.network' ;;
        NODE_NAME)       printf 'Node name shown on stats.apothem.network' ;;
        CONTACT_DETAILS) printf 'Operator email address' ;;
        NETWORK)         printf 'Network identifier (informational)' ;;
        LOG_LEVEL)       printf 'Log verbosity  [0 silent → 5 detail]' ;;
        SYNC_MODE)       printf 'Blockchain sync strategy  [full]' ;;
        GC_MODE)         printf 'State history  [archive = keep all | full = prune]' ;;
        ENABLE_RPC)      printf 'Enable HTTP-RPC server  [true | false]' ;;
        ENABLE_WS)       printf 'Enable WebSocket server  [true | false]' ;;
        RPC_PORT)        printf 'HTTP-RPC listening port (host network)' ;;
        WS_PORT)         printf 'WebSocket listening port (host network)' ;;
        API)             printf 'Comma-separated API namespaces for RPC and WS' ;;
        ALLOWED_ORIGINS) printf 'CORS allowed origins — restrict in production' ;;
        RPC_VHOSTS)      printf 'Allowed virtual hostnames for RPC — restrict in production' ;;
        *)               printf '' ;;
    esac
}

# Prompt for a single variable; writes KEY=value to TMPFILE
ask() {
    local key="$1" current="$2"
    local desc
    desc=$(desc_of "$key")

    printf "\n"
    printf "  ${BOLD}${CYAN}%-20s${NC}" "$key"
    [ -n "$desc" ] && printf "  ${DIM}%s${NC}" "$desc"
    printf "\n"
    printf "  Keep [${GREEN}%s${NC}] or enter new value: " "$current"

    local input
    read -r input </dev/tty || input=""
    local chosen="${input:-$current}"
    printf '%s=%s\n' "$key" "$chosen" >> "$TMPFILE"

    # Warn and force full if fast sync mode is set
    if [ "$key" = "SYNC_MODE" ] && [ "$chosen" = "fast" ]; then
        printf "\n  ${BOLD}${RED}WARNING:${NC} SYNC_MODE=fast is currently broken and not supported.\n"
        printf "  ${YELLOW}Forcing SYNC_MODE=full.${NC}\n"
        chosen="full"
        # Overwrite the last line in TMPFILE with the corrected value
        sed -i '' '$d' "$TMPFILE"
        printf '%s=%s\n' "$key" "$chosen" >> "$TMPFILE"
    fi

    # Warn about dangerous API namespaces
    if [ "$key" = "API" ]; then
        local dangerous=""
        for ns in admin debug personal miner; do
            if printf '%s' "$chosen" | grep -qiE "(^|,)[[:space:]]*${ns}[[:space:]]*(,|$)"; then
                dangerous="${dangerous} ${ns}"
            fi
        done
        if [ -n "$dangerous" ]; then
            printf "\n  ${BOLD}${RED}WARNING:${NC} API includes dangerous namespace(s):${RED}%s${NC}\n" "$dangerous"
            printf "  ${YELLOW}These expose node management and sensitive tracing methods.\n"
            printf "  Never enable them with ALLOWED_ORIGINS=* or on a public-facing node.${NC}\n"
        fi
    fi
}

# ── banner ────────────────────────────────────────────────────────────────────
clear
printf "\n"
printf "  ${BOLD}${BLUE}XinFin Node — Config Wizard (%s)${NC}\n" "$ENV_NAME"
printf "  %s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$ENVFILE" ]; then
    printf "  ${GREEN}Found existing${NC} %s — values pre-loaded.\n" "$ENVFILE"
else
    printf "  ${YELLOW}No .env found${NC} — defaults from %s will be used.\n" "$EXAMPLE"
fi
printf "\n"
read -rp "  Review and update .env values? [Y/n]: " do_verify </dev/tty || do_verify="Y"
do_verify="${do_verify:-Y}"

if [ "$do_verify" != "Y" ] && [ "$do_verify" != "y" ]; then
    printf "  ${YELLOW}Skipping .env review.${NC}\n"
    # Load current values into TMPFILE so the write step has something to work with
    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_][A-Z_0-9]*)= ]]; then
            key="${BASH_REMATCH[1]}"
            printf '%s=%s\n' "$key" "$(current_val "$key")" >> "$TMPFILE"
        fi
    done < "$EXAMPLE"
else
    printf "\n"
    printf "  Press ${BOLD}Enter${NC} to keep the shown value, or type a replacement.\n"
    printf "\n"
    read -rp "  Press Enter to start…" _ </dev/tty || true

    # ── collect values ────────────────────────────────────────────────────────
    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_][A-Z_0-9]*)= ]]; then
            key="${BASH_REMATCH[1]}"
            ask "$key" "$(current_val "$key")"
        fi
    done < "$EXAMPLE"

    # ── preview ───────────────────────────────────────────────────────────────
    printf "\n\n"
    printf "  ${BOLD}${BLUE}Preview — %s/.env${NC}\n" "$ENV_NAME"
    printf "  %s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_][A-Z_0-9]*)= ]]; then
            key="${BASH_REMATCH[1]}"
            printf "  ${CYAN}%-20s${NC}= ${GREEN}%s${NC}\n" "$key" "$(collected_val "$key")"
        elif [[ "$line" =~ ^# ]]; then
            printf "  ${DIM}%s${NC}\n" "$line"
        else
            printf "\n"
        fi
    done < "$EXAMPLE"

    # Repeat SYNC_MODE warning in preview
    if [ "$(collected_val "SYNC_MODE")" = "fast" ]; then
        printf "\n  ${BOLD}${RED}WARNING:${NC} SYNC_MODE=fast is currently broken and not supported.\n"
        printf "  ${YELLOW}Forcing SYNC_MODE=full.${NC}\n"
    fi

    # Repeat API warning in preview so it's visible before the save prompt
    api_val=$(collected_val "API")
    dangerous=""
    for ns in admin debug personal miner; do
        if printf '%s' "$api_val" | grep -qiE "(^|,)[[:space:]]*${ns}[[:space:]]*(,|$)"; then
            dangerous="${dangerous} ${ns}"
        fi
    done
    if [ -n "$dangerous" ]; then
        printf "\n  ${BOLD}${RED}WARNING:${NC} API contains dangerous namespace(s):${RED}%s${NC}\n" "$dangerous"
        printf "  ${YELLOW}These expose node management and sensitive tracing methods.\n"
        printf "  Never enable them with ALLOWED_ORIGINS=* or on a public-facing node.${NC}\n"
    fi

    printf "\n"
    read -rp "  Save to $ENVFILE? [Y/n]: " confirm </dev/tty || confirm="Y"
    confirm="${confirm:-Y}"

    if [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
        printf "\n  ${YELLOW}Aborted.${NC} No changes written.\n\n"
        exit 0
    fi
fi

# ── write ─────────────────────────────────────────────────────────────────────
if [ -f "$ENVFILE" ]; then
    cp "$ENVFILE" "${ENVFILE}.bak"
    printf "\n  Backed up existing .env → ${DIM}%s.bak${NC}\n" "$ENVFILE"
fi

{
    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_][A-Z_0-9]*)= ]]; then
            key="${BASH_REMATCH[1]}"
            printf '%s=%s\n' "$key" "$(collected_val "$key")"
        else
            printf '%s\n' "$line"
        fi
    done < "$EXAMPLE"
} > "$ENVFILE"

printf "  ${GREEN}${BOLD}Saved!${NC} %s written.\n\n" "$ENVFILE"

# ── restart ───────────────────────────────────────────────────────────────────
read -rp "  Restart node now? Runs docker-down.sh then docker-up.sh [Y/n]: " restart </dev/tty || restart="Y"
restart="${restart:-Y}"

if [ "$restart" != "N" ] && [ "$restart" != "n" ]; then
    if [ ! -f "$DIR/docker-down.sh" ] || [ ! -f "$DIR/docker-up.sh" ]; then
        printf "\n  ${RED}Error:${NC} docker-down.sh or docker-up.sh not found in %s\n\n" "$DIR"
        exit 1
    fi
    printf "\n  Stopping node…\n"
    (cd "$DIR" && bash docker-down.sh)
    printf "\n  Starting node…\n"
    (cd "$DIR" && bash docker-up.sh)
    printf "\n  ${GREEN}${BOLD}Node restarted.${NC}\n\n"
else
    printf "\n  Skipped. Run manually when ready:\n"
    printf "    ${DIM}bash %s/docker-down.sh && bash %s/docker-up.sh${NC}\n\n" "$DIR" "$DIR"
fi
