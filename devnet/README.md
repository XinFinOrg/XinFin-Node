# Devnet

Deploy devnet XDC node.

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

instance: XDC/v2.7.0-devnet-0227ca9b/linux-amd64/go1.25.9
```
