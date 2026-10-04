# XinFin Testnet (Apothem) Node — Nethermind Client

Runs an XDC testnet node with the [Nethermind](https://github.com/NethermindEth/nethermind) execution client.

```bash
cp env.example .env
bash docker-up.sh
```

Stop it with `bash docker-down.sh`.

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `NETWORK` | Yes | `xdc-testnet` | Config preset built into the image (`configs/xdc-testnet.json`) |
| `EC_IMAGE_VERSION` | Yes | `nethermindeth/nethermind:master-c88b947` | Nethermind Docker image |
| `NETHERMIND_LOG_LEVEL` | No | `info` | One of `trace`, `debug`, `info`, `warn`, `error` |
| `EC_DATA_DIR` | Yes | `./execution-data` | Host directory for chain data |
| `RPC_PORT` | Yes | `8505` | JSON-RPC port, published on the host |
| `RPC_MODULES` | No | `Eth,Net,Web3,Xdc,Health` | JSON-RPC namespaces to enable. See `env.example` for the full list; avoid `Parity`, `Evm`, `Admin`, `Personal`, `Trace` and `Debug` on a public port. Add `Rpc` to use the XDC console (`XDC attach`) |
| `SYNC_MODE` | No | `fast` | `fast` starts from a pivot block (`--Sync.FastSync=true`); `full` executes every block from genesis |
| `FASTSYNC_PIVOT_NUMBER` | No | — | Fast-sync pivot block number (`--Sync.PivotNumber`) |
| `FASTSYNC_PIVOT_HASH` | No | — | Fast-sync pivot block hash (`--Sync.PivotHash`) |
| `FASTSYNC_PIVOT_TOTAL_DIFFICULTY` | No | — | Total difficulty at the pivot block (`--Sync.PivotTotalDifficulty`) |
| `GC_MODE` | No | `full` | `full` prunes old state (`--Pruning.Mode=Hybrid`); `archive` keeps it (`--Pruning.Mode=None`) |

`start.sh` builds the Nethermind flags from these variables and launches the node, the same way the XDC client's start script does. Add any other Nethermind setting as a `--Section.Key=value` entry in its `args` list.

The pivot variables must be set together or all left blank. Blank uses the pivot built into the image. Get current values with `../tools/get_pivot_for_fast_sync.sh testnet`, which prints `FASTSYNC_PIVOT_TOTAL_DIFFICULTY` alongside the XDC client's values. Unlike the XDC client, Nethermind needs the pivot's total difficulty rather than its state root.

With `SYNC_MODE=fast`, `GC_MODE=archive` keeps full state only from the pivot onward; use `SYNC_MODE=full` as well for an archive from genesis. Sync and GC settings only take effect on an empty data directory.

The XDC client's `STORE_REWARD` and `CHAIN_CONFIG_MISMATCH_POLICY` have no Nethermind equivalent and are not used here.

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| `30306` | TCP + UDP | P2P and discovery |
| `RPC_PORT` | TCP | JSON-RPC |

## Bootnodes

Bootnodes come from [`../bootnodes/testnet.list`](../bootnodes/testnet.list), the same list the XDC client uses. `start.sh` joins the file into `--Network.Bootnodes` at startup, so edit the list and restart the node to change them. If the file is missing or empty, the node falls back to the chainspec built into the image (`chainspec/xdc-testnet.json`).

> Testnet XDC nodes currently accept only the DK04 hub as a peer (`--peers-allowlist`), so other bootnodes disconnect a Nethermind node right after the handshake. `start.sh` therefore adds the hub as a static peer (`--Network.StaticPeers`).
