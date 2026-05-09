# XinFin Testnet (Apothem) Node — Environment Configuration

Copy `env.example` to `.env` and fill in your values before starting the node.

```bash
cp env.example .env
```

---

## Environment Variables

### Node Identity

| Variable | Required | Default | Description |
|---|---|---|---|
| `NODE_NAME` | Yes | `XF_MasterNode` | Name shown on the [Apothem stats dashboard](https://stats.apothem.network) |
| `CONTACT_DETAILS` | Yes | — | Operator email address, shown on the stats dashboard |
| `NETWORK` | No | `testnet` | Network identifier (informational) |

### Logging

| Variable | Required | Default | Description |
|---|---|---|---|
| `LOG_LEVEL` | No | `2` | Verbosity level passed to `--verbosity`. Range: `0` (silent) – `5` (detail) |

### Sync & Storage

| Variable | Required | Default | Description |
|---|---|---|---|
| `SYNC_MODE` | No | `full` | Blockchain sync mode: `full` or `fast` |
| `GC_MODE` | No | `archive` | Garbage-collection mode: `archive` (keeps all state) or `full` (prunes old state) |

> Use `GC_MODE=archive` if you need to query historical state. `GC_MODE=full` saves significant disk space for a standard validator or relay node.

### HTTP-RPC (JSON-RPC)

| Variable | Required | Default | Description |
|---|---|---|---|
| `ENABLE_RPC` | No | `false` | Set to `true` to enable the HTTP-RPC server. Any other value disables it. |
| `RPC_PORT` | No | `8545` | Internal container port for HTTP-RPC (mapped to host port `8989` in docker-compose). |
| `API` | No | `db,eth,net,txpool,web3,XDPoS` | Comma-separated list of API namespaces exposed over RPC and WebSocket |
| `ALLOWED_ORIGINS` | No | `*` | CORS allowed origins for RPC/WS requests. Use a specific domain in production. |
| `RPC_VHOSTS` | No | `*` | Allowed virtual hostnames for the RPC server. Use a specific hostname in production. |

### WebSocket

| Variable | Required | Default | Description |
|---|---|---|---|
| `ENABLE_WS` | No | `false` | Set to `true` to enable the WebSocket server. Any other value disables it. |
| `WS_PORT` | No | `8546` | Internal container port for WebSocket (mapped to host port `8888` in docker-compose). |

---

## Port Reference

The container runs with `network_mode: host` — ports bind directly on the host, there is no Docker port mapping. The ports below reflect the defaults; set `RPC_PORT` and `WS_PORT` in `.env` to use different values.

| Port | Protocol | Purpose | Controlled By |
|---|---|---|---|
| `30312` | TCP/UDP | P2P peer discovery and block sync | Always open |
| `RPC_PORT` (default `8545`) | TCP | HTTP-RPC (JSON-RPC) | `ENABLE_RPC=true` |
| `WS_PORT` (default `8546`) | TCP | WebSocket RPC | `ENABLE_WS=true` |

> Port `30312` must be reachable from the internet for the node to connect to peers. The RPC and WebSocket ports are only active when their respective `ENABLE_*` flags are set to `true`; the process explicitly passes `--http=false` / `--ws=false` otherwise.

---

## XDC Node Flags

These flags are passed to the `XDC` binary by `start-apothem.sh`. Most are derived from the env variables above.

| Flag | Value / Source | Description |
|---|---|---|
| `--ethstats` | `NODE_NAME` + stats server | Reports node status to the Apothem stats dashboard |
| `--bootnodes` | `bootnodes.list` | Comma-separated enode URLs used for initial peer discovery |
| `--syncmode` | `SYNC_MODE` | Blockchain sync strategy (`full` or `fast`) |
| `--gcmode` | `GC_MODE` | State trie garbage-collection mode (`archive` or `full`) |
| `--datadir` | `/work/xdcchain` | Directory for chain data and keystore |
| `--XDCx.datadir` | `/work/xdcchain/XDCx` | Directory for XDCx (DEX) data |
| `--networkid` | `51` | XinFin Apothem testnet chain ID |
| `--port` | `30312` | P2P listening port |
| `--unlock` | wallet address | Unlocks the node account for mining |
| `--password` | `/work/.pwd` | Path to the keystore password file |
| `--mine` | — | Enables block mining / validator participation |
| `--gasprice` | `1` | Minimum gas price (in Wei) accepted for transactions |
| `--targetgaslimit` | `420000000` | Target block gas limit |
| `--verbosity` | `LOG_LEVEL` | Log verbosity (0–5) |
| `--store-reward` | — | Persists block reward data for validators |
| `--http` | `ENABLE_RPC=true` | Enables the HTTP-RPC server |
| `--http-addr` | `0.0.0.0` | Binds RPC to all interfaces |
| `--http-port` | `RPC_PORT` | HTTP-RPC listening port |
| `--http-api` | `API` | Enabled API namespaces over HTTP-RPC |
| `--http-corsdomain` | `ALLOWED_ORIGINS` | Allowed CORS origins for RPC |
| `--http-vhosts` | `RPC_VHOSTS` | Allowed virtual hostnames for RPC |
| `--ws` | `ENABLE_WS=true` | Enables the WebSocket server |
| `--ws-addr` | `0.0.0.0` | Binds WebSocket to all interfaces |
| `--ws-port` | `WS_PORT` | WebSocket listening port |
| `--ws-api` | `API` | Enabled API namespaces over WebSocket |
| `--ws-origins` | `ALLOWED_ORIGINS` | Allowed origins for WebSocket connections |

---

## Security Notes

- **RPC and WebSocket are disabled by default.** Enable them only if your use case requires external API access.
- When enabling RPC/WS, restrict `ALLOWED_ORIGINS` and `RPC_VHOSTS` to known domains rather than leaving them as `*`.
- The container uses `network_mode: host` — there is no Docker port mapping layer. Host-level firewall rules are the only protection for RPC/WS ports.
- Port `30312` should be open to the internet for proper peer connectivity.
