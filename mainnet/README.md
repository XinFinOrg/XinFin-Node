# XinFin Mainnet Node — Environment Configuration

Copy `env.example` to `.env` and fill in your values before starting the node.

```bash
cp env.example .env
```

---

## Environment Variables

### Node Identity

| Variable | Required | Default | Description |
|---|---|---|---|
| `INSTANCE_NAME` | Yes | — | Name shown on the [network stats dashboard](https://stats.xinfin.network) |
| `CONTACT_DETAILS` | Yes | — | Operator email address, shown on the stats dashboard |
| `NETWORK` | No | `mainnet` | Network identifier (informational) |

### Logging

| Variable | Required | Default | Description |
|---|---|---|---|
| `LOG_LEVEL` | No | `2` | Verbosity level passed to `--verbosity`. Range: `0` (silent) – `5` (detail) |

### Sync & Storage

| Variable | Required | Default | Description |
|---|---|---|---|
| `SYNC_MODE` | No | `full` | Blockchain sync mode: `full` (replay every block) or `fast` (download state at a pivot and replay from there). `fast` requires the `FASTSYNC_PIVOT_*` variables below. |
| `GC_MODE` | No | `archive` | Garbage-collection mode: `archive` (keeps all state) or `full` (prunes old state) |

> Use `GC_MODE=archive` if you need to query historical state (e.g. for an explorer or analytics node). `GC_MODE=full` saves significant disk space for a standard validator or relay node.

### Fast Sync Pivot

Required only when `SYNC_MODE=fast`. All three variables must be set together — `start-node.sh` will refuse to start if only some are provided.

| Variable | Required | Default | Description |
|---|---|---|---|
| `FASTSYNC_PIVOT_NUMBER` | If `SYNC_MODE=fast` | — | Block number to fast-sync to (the pivot). Passed as `--fastsyncpivotnumber`. |
| `FASTSYNC_PIVOT_HASH` | If `SYNC_MODE=fast` | — | Hash of the pivot block. Passed as `--fastsyncpivothash`. |
| `FASTSYNC_PIVOT_ROOT` | If `SYNC_MODE=fast` | — | State root of the pivot block. Passed as `--fastsyncpivotroot`. |

> Run `bash get_pivot_for_fast_sync.sh` to extract a fresh pivot (block number, hash, and state root) from a public XinFin RPC node. The script prints the values in `.env` format, so you can append the output directly:
>
> ```bash
> bash get_pivot_for_fast_sync.sh >> .env
> ```
>
> The script defaults to `https://erpc.xinfin.network` and can be pointed at another endpoint with `RPC_URL=... bash get_pivot_for_fast_sync.sh`. It requires `jq` and `curl`.

### HTTP-RPC (JSON-RPC)

| Variable | Required | Default | Description |
|---|---|---|---|
| `ENABLE_RPC` | No | `false` | Set to `true` to enable the HTTP-RPC server. Any other value disables it. |
| `RPC_PORT` | No | `8545` | Host port the HTTP-RPC server listens |
| `API` | No | `db,eth,net,txpool,web3,XDPoS` | Comma-separated list of API namespaces exposed over RPC and WebSocket |
| `ALLOWED_ORIGINS` | No | `*` | CORS allowed origins for RPC/WS requests. Use a specific domain in production. |
| `RPC_VHOSTS` | No | `*` | Allowed virtual hostnames for the RPC server (`--http-vhosts`). Use a specific hostname in production. |

### WebSocket

| Variable | Required | Default | Description |
|---|---|---|---|
| `ENABLE_WS` | No | `false` | Set to `true` to enable the WebSocket server. Any other value disables it. |
| `WS_PORT` | No | `8546` | Host port the WebSocket server listens on |

---

## Port Reference

The container runs with `network_mode: host` — ports bind directly on the host, there is no Docker port mapping. The ports below reflect the defaults; set `RPC_PORT` and `WS_PORT` in `.env` to use different values.

| Port | Protocol | Purpose | Controlled By |
|---|---|---|---|
| `30303` | TCP/UDP | P2P peer discovery and block sync | Always open |
| `RPC_PORT` (default `8545`) | TCP | HTTP-RPC (JSON-RPC) | `ENABLE_RPC=true` |
| `WS_PORT` (default `8546`) | TCP | WebSocket RPC | `ENABLE_WS=true` |

> Port `30303` must be reachable from the internet for the node to connect to peers. The RPC and WebSocket ports are only active when their respective `ENABLE_*` flags are set to `true`; the process explicitly passes `--http=false` / `--ws=false` otherwise.

---

## XDC Node Flags

These flags are passed to the `XDC` binary by `start-node.sh`. Most are derived from the env variables above.

| Flag | Value / Source | Description |
|---|---|---|
| `--ethstats` | `INSTANCE_NAME` + stats server | Reports node status to the XinFin stats dashboard |
| `--bootnodes` | `bootnodes.list` | Comma-separated enode URLs used for initial peer discovery |
| `--syncmode` | `SYNC_MODE` | Blockchain sync strategy (`full` or `fast`) |
| `--gcmode` | `GC_MODE` | State trie garbage-collection mode (`archive` or `full`) |
| `--fastsyncpivotnumber` | `FASTSYNC_PIVOT_NUMBER` | Pivot block number for `SYNC_MODE=fast` |
| `--fastsyncpivothash` | `FASTSYNC_PIVOT_HASH` | Pivot block hash for `SYNC_MODE=fast` |
| `--fastsyncpivotroot` | `FASTSYNC_PIVOT_ROOT` | Pivot block state root for `SYNC_MODE=fast` |
| `--datadir` | `/work/xdcchain` | Directory for chain data and keystore |
| `--XDCx.datadir` | `/work/xdcchain/XDCx` | Directory for XDCx (DEX) data |
| `--networkid` | `50` | XinFin mainnet chain ID |
| `--port` | `30303` | P2P listening port |
| `--unlock` | wallet address | Unlocks the node account for mining |
| `--password` | `/work/.pwd` | Path to the keystore password file |
| `--mine` | — | Enables block mining / validator participation |
| `--gasprice` | `1` | Minimum gas price (in Wei) accepted for transactions |
| `--targetgaslimit` | `420000000` | Target block gas limit |
| `--verbosity` | `LOG_LEVEL` | Log verbosity (0–5) |
| `--store-reward` | — | Persists block reward data for validators |
| `--http` | `ENABLE_RPC=true` | Enables the HTTP-RPC server |
| `--http-addr` | `0.0.0.0` | Binds RPC to all interfaces inside the container |
| `--http-port` | `RPC_PORT` | HTTP-RPC listening port |
| `--http-api` | `API` | Enabled API namespaces over HTTP-RPC |
| `--http-corsdomain` | `ALLOWED_ORIGINS` | Allowed CORS origins for RPC |
| `--http-vhosts` | `RPC_VHOSTS` | Allowed virtual hostnames for RPC |
| `--ws` | `ENABLE_WS=true` | Enables the WebSocket server |
| `--ws-addr` | `0.0.0.0` | Binds WebSocket to all interfaces inside the container |
| `--ws-port` | `WS_PORT` | WebSocket listening port |
| `--ws-api` | `API` | Enabled API namespaces over WebSocket |
| `--ws-origins` | `ALLOWED_ORIGINS` | Allowed origins for WebSocket connections |

---

## Security Notes

- **RPC and WebSocket are disabled by default.** Enable them only if your use case requires external API access.
- When enabling RPC/WS, restrict `ALLOWED_ORIGINS` and `RPC_VHOSTS` to known domains rather than leaving them as `*`.
- The container uses `network_mode: host` — there is no Docker port mapping layer. Host-level firewall rules are the only protection for RPC/WS ports.
- Port `30303` should be open to the internet for proper peer connectivity.
