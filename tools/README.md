# fast-sync

Scripts to compute the fast-sync pivot point for an XDC node.

## Scripts

### `get_pivot.sh`

Computes the fast-sync pivot from the **latest V2 epoch** using `XDPoS_getMasternodesByNumber` and `XDPoS_getBlockInfoByV2EpochNum`.

Use this for networks running XDPoS v2.

```bash
./get_pivot.sh
```

### `get_pivot_more.sh`

Computes the fast-sync pivot by reading epoch parameters from a local `genesis.json` file and calculating the current epoch from the latest round. Uses `XDPoS_getBlockInfoByEpochNum`.

Use this when you need to derive the epoch from genesis config (e.g. for V1/V2 boundary networks).

```bash
./get_pivot_more.sh [genesis.json]
```

The genesis file argument defaults to `genesis.json` in the current directory.

## Environment Variables

| Variable  | Default                                                   | Description              |
|-----------|-----------------------------------------------------------|--------------------------|
| `RPC_URL` | `https://devnetstats.hashlabs.apothem.network/rpc2/`     | JSON-RPC endpoint to use |

### Example

```bash
RPC_URL=http://localhost:8545 ./get_pivot.sh
```

## Output

Both scripts print the pivot values as environment variable assignments:

```
FASTSYNC_PIVOT_NUMBER=<block number>
FASTSYNC_PIVOT_HASH=<block hash>
FASTSYNC_PIVOT_ROOT=<state root>
```

These can be sourced directly or passed to your node's fast-sync configuration.

## Dependencies

- `curl`
- `jq`
