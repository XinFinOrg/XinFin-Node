# Releasenet

Deploy releasenet XDC node.

## Usage

Start the releasenet:

```sh
./docker-up.sh
```

Shut down the releasenet:

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

instance: XDC/v2.7.0-releasenet-0227ca9b/linux-amd64/go1.25.9
```
