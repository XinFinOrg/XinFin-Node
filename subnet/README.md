# Subnet
XDC subnet is a blockchain network tailored for private and consortium use cases. It is powered by XDC2.0, which is the core engine of XDC network and enables state-of-the-art security against Byzantine attacks with forensics, fast transaction confirmation, and low energy consumption. It is also designed to enable secure checkpointing to XDC mainnet, so that it can harness the security, finality, and accountability of mainnet.

For more information, see https://xinfinorg.github.io/xdc-subnet-docs/category/subnet-chain

## How to start your own XDC subnet
### Bootnode
1. Create an file with name of `.env.bootnode`
2. Make sure below values are populated in the .env.bootnode file:
  - EXTIP: Your host external IP address. This is useful if you want your bootnode to be discoveryed outside of your local network.
  - NET_RESTRICTING (Optional): This restrict p2p connectivity to an IP subnet. It will further isolate the network and prevents cross-connecting with other blockchain networks in case the nodes are reachable from the Internet. example value `172.16.254.0/24`. With the this setting, bootnode will only allow connections from the 172.16.254.0/24 subnet, and will not attempt to connect to other nodes outside of the set IP range.
3. Run `docker-compose up bootnode`. Copy the bootnode address which looks like `enode://blabla@[some-ip-address]:30301`

### Subnet node
1. Copy the `.env.example` and name it to `.env`
2. Replace the environment variables in the `.env` with your own ones:
  - INSTANCE_NAME={{Name of the instance}}
  - BOOTNODES: Addresses of the bootnodes, seperated by ",". You should already have this value when you spin up the bootnode from the section above
  - PRIVATE_KEY: Primary key of the wallet. Note, if not provided, the node will run on a random key
  - NETWORK_ID: The subnet network id. This shall be unique in your local network. Default to 102 if not provided.
  - RPC_API (Optional): The API that you would like to turn on. Supported values are "admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS"
  - EXTIP (Optional): NAT port mapping based on the external IP address.
  - SYNC_MODE (Optional): The node syncing mode. Available values are full or fast. Default to full.
  - LOG_LEVEL (Optional): {{Log level, from 1 to 5 where 1 produce least logs. default to 3 if not provided}}
3. Provide your own `genesis.json` file
  - Follow WIP if you do not have genesis file yet (Working in progress) OR use the "genesis.json.example" as an example
4. Run `docker-compose up subnet`


### Restart from fresh?
If you have already ran the nodes before and would like to start from completely fresh, you will need to nuke the stored chain data first.
Run below before running all the necessary from "How to start your own XDC subnet" again.
```
rm -rf xdcchain
```