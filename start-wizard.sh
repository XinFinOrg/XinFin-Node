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
        SYNC_MODE)             printf 'Blockchain sync strategy  [full | fast]' ;;
        FASTSYNC_PIVOT_NUMBER) printf 'Fast-sync pivot block number (auto-set when SYNC_MODE=fast)' ;;
        FASTSYNC_PIVOT_HASH)   printf 'Fast-sync pivot block hash (auto-set when SYNC_MODE=fast)' ;;
        FASTSYNC_PIVOT_ROOT)   printf 'Fast-sync pivot state root (auto-set when SYNC_MODE=fast)' ;;
        GC_MODE)               printf 'State history  [archive = keep all | full = prune]' ;;
        STORE_REWARD)    printf 'Store block reward info  [true | false]' ;;
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

# ── git update check ──────────────────────────────────────────────────────────
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
    printf "\n  Checking for remote updates…\n"
    if git -C "$REPO_ROOT" fetch --quiet 2>/dev/null; then
        BEHIND=$(git -C "$REPO_ROOT" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
        if [ "$BEHIND" -gt 0 ] 2>/dev/null; then
            printf "  ${YELLOW}${BOLD}%s new commit(s) available from remote.${NC}\n" "$BEHIND"
            read -rp "  Pull latest changes? [Y/n]: " do_pull </dev/tty || do_pull="Y"
            do_pull="${do_pull:-Y}"
            if [ "$do_pull" != "N" ] && [ "$do_pull" != "n" ]; then
                printf "  Pulling latest changes…\n"
                if git -C "$REPO_ROOT" pull; then
                    printf "  ${GREEN}${BOLD}Updated successfully.${NC}\n"
                else
                    printf "  ${RED}git pull failed. Continuing without update.${NC}\n"
                fi
            else
                printf "  ${YELLOW}Skipping update.${NC}\n"
            fi
        else
            printf "  ${GREEN}Already up to date.${NC}\n"
        fi
    else
        printf "  ${DIM}Could not reach remote — skipping update check.${NC}\n"
    fi
fi

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
            # Fast sync pivot vars are auto-computed; skip interactive prompts
            [[ "$key" == FASTSYNC_PIVOT_* ]] && continue
            ask "$key" "$(current_val "$key")"
        fi
    done < "$EXAMPLE"

    # ── fast sync pivot ───────────────────────────────────────────────────────
    _set_pivot_vals() {
        local num="$1" hash="$2" root="$3"
        for _k in FASTSYNC_PIVOT_NUMBER FASTSYNC_PIVOT_HASH FASTSYNC_PIVOT_ROOT; do
            grep -v "^${_k}=" "$TMPFILE" > "${TMPFILE}.tmp" && mv "${TMPFILE}.tmp" "$TMPFILE"
        done
        printf 'FASTSYNC_PIVOT_NUMBER=%s\n' "$num"  >> "$TMPFILE"
        printf 'FASTSYNC_PIVOT_HASH=%s\n'   "$hash" >> "$TMPFILE"
        printf 'FASTSYNC_PIVOT_ROOT=%s\n'   "$root" >> "$TMPFILE"
    }

    if [ "$(collected_val "SYNC_MODE")" = "fast" ]; then
        printf "\n\n"
        printf "  ${BOLD}${BLUE}Fast Sync — Fetching Pivot Point${NC}\n"
        printf "  %s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        printf "\n"
        printf "  A trusted pivot block is required for fast sync.\n"
        printf "  The wizard will query a public RPC endpoint to compute it.\n"
        printf "\n"

        if [ "$ENV_NAME" = "mainnet" ]; then
            _default_rpc="https://rpc.xinfin.network"
        elif [ "$ENV_NAME" = "testnet" ]; then
            _default_rpc="https://erpc.apothem.network"
        fi
        _pivot_script="$REPO_ROOT/tools/get_pivot.sh"

        printf "  RPC endpoint [${GREEN}%s${NC}] or enter new: " "$_default_rpc"
        read -r _rpc_input </dev/tty || _rpc_input=""
        _pivot_rpc="${_rpc_input:-$_default_rpc}"

        printf "\n  Fetching pivot from %s…\n" "$_pivot_rpc"
        _pivot_out=$(RPC_URL="$_pivot_rpc" bash "$_pivot_script" 2>/dev/null)
        _pivot_rc=$?

        if [ $_pivot_rc -ne 0 ] || ! printf '%s' "$_pivot_out" | grep -q '^FASTSYNC_PIVOT_NUMBER='; then
            printf "\n  ${RED}${BOLD}Error:${NC} Failed to fetch pivot point from %s\n" "$_pivot_rpc"
            printf "  ${YELLOW}Falling back to SYNC_MODE=full.${NC}\n"
            grep -v "^SYNC_MODE=" "$TMPFILE" > "${TMPFILE}.tmp" && mv "${TMPFILE}.tmp" "$TMPFILE"
            printf 'SYNC_MODE=full\n' >> "$TMPFILE"
            _set_pivot_vals "" "" ""
        else
            _pnum=$(printf '%s' "$_pivot_out" | grep '^FASTSYNC_PIVOT_NUMBER=' | cut -d'=' -f2-)
            _phash=$(printf '%s' "$_pivot_out" | grep '^FASTSYNC_PIVOT_HASH='   | cut -d'=' -f2-)
            _proot=$(printf '%s' "$_pivot_out" | grep '^FASTSYNC_PIVOT_ROOT='   | cut -d'=' -f2-)
            printf "\n  ${GREEN}${BOLD}Pivot fetched successfully:${NC}\n"
            printf "  ${CYAN}FASTSYNC_PIVOT_NUMBER${NC} = ${GREEN}%s${NC}\n" "$_pnum"
            printf "  ${CYAN}FASTSYNC_PIVOT_HASH${NC}   = ${GREEN}%s${NC}\n" "$_phash"
            printf "  ${CYAN}FASTSYNC_PIVOT_ROOT${NC}   = ${GREEN}%s${NC}\n" "$_proot"
            _set_pivot_vals "$_pnum" "$_phash" "$_proot"
        fi
    else
        _set_pivot_vals "" "" ""
    fi

    # ── preview ───────────────────────────────────────────────────────────────
    printf "\n\n"
    printf "  ${BOLD}${BLUE}Preview — %s/.env${NC}\n" "$ENV_NAME"
    printf "  %s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Z_][A-Z_0-9]*)= ]]; then
            key="${BASH_REMATCH[1]}"
            printf "  ${CYAN}%-22s${NC}= ${GREEN}%s${NC}\n" "$key" "$(collected_val "$key")"
        elif [[ "$line" =~ ^# ]]; then
            printf "  ${DIM}%s${NC}\n" "$line"
        else
            printf "\n"
        fi
    done < "$EXAMPLE"

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
