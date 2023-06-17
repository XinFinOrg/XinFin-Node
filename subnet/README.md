# Subnet
XDC subnet is a blockchain network tailored for private and consortium use cases. It is powered by XDC2.0, which is the core engine of XDC network and enables state-of-the-art security against Byzantine attacks with forensics, fast transaction confirmation, and low energy consumption. It is also designed to enable secure checkpointing to XDC mainnet, so that it can harness the security, finality, and accountability of mainnet.

For more information, see https://xinfinorg.github.io/xdc-subnet-docs/category/subnet-chain

## How to start your own XDC subnet

## Pre-requisite
- [Docker](https://docs.docker.com/get-docker/)
- Several host machines (>=3)
- Prepare your nodes private key and address from `address-creator` in this repository

### Step 0: Set up environment
1. Vist [https://github.com/XinFinOrg/XinFin-Node](https://github.com/XinFinOrg/XinFin-Node) and clone the code. i.e `git clone https://github.com/XinFinOrg/XinFin-Node`
2. Check the `subnet` directory. i.e `cd subnet`
3. Create empty environment files by running `./start.sh` (You may need admin permission to create file, run with `sudo bash ./start.sh`)

### Step 1: Host your bootnode
A subnet bootnode is a special node needed for the initialization and growth of the P2P network in a subnet. It does this by providing new nodes a list of active peers and their IP addresses. Bootnodes do not have any special privileges. They are responsible for network discovery rather than block validation or transaction processing.

1. Find the file with name of `.env.bootnode`
2. Make sure below values are populated in the `.env.bootnode` file:
  - EXTIP: Your host external IP address. This is useful if you want your bootnode to be discoveryed outside of your local network.
  - NET_RESTRICTING (Optional): This restrict p2p connectivity to an IP subnet. It will further isolate the network and prevents cross-connecting with other blockchain networks in case the nodes are reachable from the Internet. example value `172.16.254.0/24`. With the this setting, bootnode will only allow connections from the 172.16.254.0/24 subnet, and will not attempt to connect to other nodes outside of the set IP range.
3. Run `docker-compose up bootnode`. Copy the bootnode address which looks like `enode://blabla@[some-ip-address]:30301`. You can find this information under the file `bootnodes/bootnodes.list`

### Step 2: Generate your genesis file
In the context of XinFin XDC (XinFin Digital Contract), the genesis file refers to a configuration file that contains the initial parameters and settings for the blockchain network. It is an essential component used during the initialization process when creating a new XinFin blockchain network.

The genesis file defines various parameters, such as the initial block data, the initial set of validators, the block time, consensus algorithm settings, network ID, and other network-specific configurations. It serves as a blueprint for the blockchain's initial state and determines how the network will be set up and operate from the very beginning.

When launching a new XinFin XDC network, the genesis file is typically created and distributed to all participating nodes. Each node in the network references this file during the initialization process to ensure they have a consistent starting point for the blockchain's state. This ensures that all nodes agree on the initial conditions and can validate and agree upon subsequent transactions and blocks in a decentralized manner.

The genesis file is crucial for establishing the network's foundation and provides the initial rules and parameters for the XinFin XDC blockchain.

1. Run `docker-compose run puppeth` and follow its instructions, specifically
  - when seeing "Please specify a network name to administer", enter the network name as you wish. e.g., network001.
  - when seeing "What would you like to do?", choose "2. Configure new genesis".
  - when seeing "Which consensus engine to use?", choose "3. XDPoS - delegated-proof-of-stake".
  - as for other options, choose the options as you wish.
  - after the last step which is "Specify your chain/network ID if you want an explicit one", your genesis file is generated in your home directory and you can push "Ctrl-C" to exit `puppeth`.
2. Open the generated file under the `./puppeth` directory. Copy the value of key `genesis`. Keep it somewhere safe for later usage.

### Step 3: Host your subnet xdc-nodes
1. Find the file with name `.env`
2. Fill in the environment variables in the `.env`:
  - INSTANCE_NAME: Name of the instance
  - BOOTNODES: Addresses of the bootnodes, seperated by ",". You should already have this value when you spin up the bootnode from the section above
  - PRIVATE_KEY: Primary key of the wallet. Note, if not provided, the node will run on a random key
  - NETWORK_ID: The subnet network id. This shall be unique in your local network. Default to 102 if not provided.
  - STATS_SECRET: A secret that you used between your stats service and the subnet node. (This value need to match with Step 4 STATS_SECRET)
  - STATS_SERVICE_ADDRESS: The backend service that was created at step 1 for the UI representation of the subnet blockchain.
  - RPC_API (Optional): The API that you would like to turn on. Supported values are "admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS"
  - EXTIP (Optional): NAT port mapping based on the external IP address.
  - SYNC_MODE (Optional): The node syncing mode. Available values are full or fast. Default to full.
  - LOG_LEVEL (Optional): {{Log level, from 1 to 5 where 1 produce least logs. default to 3 if not provided}}
3. Provide your own `genesis.json` file under the current directory. (The value from Step 2.4)
4. Run `docker-compose up -d subnet`

### Step 4: Host your stats service (Working In Progress)
1. Find the file with name of `.env.stats`
2. Fill in the environment variables in the `.env.stats`:
  - STATS_SECRET: A secret that you used between your stats service and the subnet node. 
3. Run `docker-compose up -d stats`