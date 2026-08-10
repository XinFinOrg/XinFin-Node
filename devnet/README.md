# Devnet (18 validators, chainId 551)

Deploy an external Docker node that joins the 18-devnet cluster.

| | |
|--|--|
| Chain ID / network ID | **551** |
| Validators | 18 (hybrid seats after round 50000) |
| Image | `xinfinorg/devnet:latest` |
| Public bootnode | `enode://03e59…@158.220.83.243:30301` |
| Stats UI | http://158.220.83.243:32018 |

Genesis matches `XDPoSChain/genesis/devnet.json` and `k8-devnet/18-devnet`.

## Usage

Start the devnet:

```sh
./docker-up.sh
```

Shut down the devnet:

```sh
./docker-down.sh
```

Attach to the console:

```sh
./attach.sh
```

## Verifying the Build Commit

After attaching, the console prints the build commit:

```text
╰─ ./attach.sh
Welcome to the XDC JavaScript console!

instance: XDC/v2.9.0-devnet-<hash>/linux-amd64/go1.25.x
```
