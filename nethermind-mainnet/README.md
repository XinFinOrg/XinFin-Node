# XinFin Mainnet Node — Nethermind Client

Runs an XDC mainnet node with the [Nethermind](https://github.com/NethermindEth/nethermind) execution client.

```bash
cp env.example .env
bash docker-up.sh
```

Stop it with `bash docker-down.sh`.

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `NETWORK` | Yes | `xdc` | Config preset built into the image (`configs/xdc.json`) |
| `EC_IMAGE_VERSION` | Yes | `nethermindeth/nethermind:master-8a2253d` | Nethermind Docker image |
| `NETHERMIND_LOG_LEVEL` | No | `info` | One of `trace`, `debug`, `info`, `warn`, `error` |
| `EC_DATA_DIR` | Yes | `./execution-data` | Host directory for chain data |
| `RPC_PORT` | Yes | `8515` | JSON-RPC port, published on the host |

`start.sh` builds the Nethermind flags from these variables and launches the node, the same way the XDC client's start script does. Add any other Nethermind setting as a `--Section.Key=value` entry in its `args` list.

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| `30301` | TCP + UDP | P2P and discovery |
| `RPC_PORT` | TCP | JSON-RPC |

## Bootnodes

Bootnodes come from [`../bootnodes/mainnet.list`](../bootnodes/mainnet.list), the same list the XDC client uses. `start.sh` joins the file into `--Network.Bootnodes` at startup, so edit the list and restart the node to change them. If the file is missing or empty, the node falls back to the chainspec built into the image (`chainspec/xdc.json`).
