# fast-sync

Scripts to compute the fast-sync pivot point for an XDC node.

## Scripts

### `get_pivot_for_fast_sync.sh`

Computes the fast-sync pivot for the given network from the **latest V2 epoch** by calculating the current epoch from the latest round. Uses `XDPoS_getMasternodesByNumber` and `XDPoS_getBlockInfoByEpochNum`.

Use this for networks running XDPoS v2. The round returned by `XDPoS_getMasternodesByNumber` is a V2 round, so the epoch it yields is offset by the network's `switchEpoch` — the epoch at which the chain switched from V1 to V2 — to give an absolute epoch number.

The network argument selects that network's epoch parameters (`epoch` and `switchEpoch`) and default RPC endpoint, and defaults to `mainnet`.

```bash
./get_pivot_for_fast_sync.sh [mainnet|testnet]
```

## Environment Variables

| Variable  | Default                                                   | Description              |
|-----------|-----------------------------------------------------------|--------------------------|
| `NETWORK` | `mainnet`                                                 | Network to use when no argument is given |
| `RPC_URL` | `https://erpc.xinfin.network` (mainnet)<br>`https://earpc.apothem.network` (testnet) | JSON-RPC endpoint to use |

### Example

```bash
RPC_URL=http://localhost:8545 ./get_pivot_for_fast_sync.sh
```

## Output

The script prints the pivot values as environment variable assignments:

```
FASTSYNC_PIVOT_NUMBER=<block number>
FASTSYNC_PIVOT_HASH=<block hash>
FASTSYNC_PIVOT_ROOT=<state root>
```

These can be sourced directly or passed to your node's fast-sync configuration.

## Dependencies

- `curl`
- `jq`
