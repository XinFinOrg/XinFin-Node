## How to Setup XinFin Masternode

### Method 1 :- Setup XinFin Masternode Bootstrap Script ###

**For Mainnet**

Bootstrap Command XinFin Node Setup:-

```
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/XinFinOrg/XinFin-Node/master/setup/bootstrap.sh)" root
```

Examples:-
```
$ sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/XinFinOrg/XinFin-Node/master/setup/bootstrap.sh)" root
[sudo] password for user:
Please enter your XinFin Network (mainnet/testnet/devnet) :- mainnet
Your running network is mainnet
Please enter your XinFin MasterNode Name :- Demo_Server
Your Masternode Name is Demo_Server

```


**For Testnet**
```
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/XinFinOrg/XinFin-Node/master/setup/bootstrap.sh)" root
Please enter your XinFin Network (mainnet/testnet/devnet) :- testnet
Your running network is testnet
Please enter your XinFin MasterNode Name :- test01
Your Masternode Name is test01
```

**For Devnet**
```
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/XinFinOrg/XinFin-Node/master/setup/bootstrap.sh)" root
Please enter your XinFin Network (mainnet/testnet/devnet) :- devnet
Your running network is devnet
Please enter your XinFin MasterNode Name :- test01
Your Masternode Name is test01
Generate new private key and wallet address.
If you have your own key, you can change after this and restart the node
Type 'Y' or 'y' to continue:
```

---------------------------------

### Method 2:- Setup XinFin Masternode Docker ###

**Operating System**: Ubuntu 20.04 64-bit or higher

**Requirements**:
- Docker Engine 24.0+ (includes Docker Compose v2)
- Docker Compose v2.20+

Should be facing internet directly with **public IP** & **without NAT**

Setup (For Ubuntu 20.04 64-bit or higher Operating System)

**Clone repository**
```
git clone https://github.com/XinFinOrg/XinFin-Node.git
```

Enter `XinFin-Node` directory
```
cd XinFin-Node
```


**Step 1: Install Docker**
    sudo ./setup/install_docker.sh

**Step 2: Update .env file with details**
Create `.env` file by using the sample - `.env.example`

Enter either your company or product name in the INSTANCE_NAME field.

Enter your email address in CONTACT_DETAILS field.

```
cd mainnet # testnet
cp env.example .env
nano .env
```

**Step 3: Start your Node**

**For Mainnet**

Run:
```
docker compose -f docker-compose.yml up -d
```

You should be able to see your node listed on the [XinFin Network](https://XinFin.network/) page.
Select Menu **"Switch to TestNet"** for **TestNetwork** and Select **"Switch to LiveNet"** to check **LiveNetwork** Stats.

Your coinbase address can be found in xdcchain/coinbase.txt file.

To stop the node or if you encounter any issues use:
```
docker compose -f docker-compose.yml down
```
Attach XDC Console:
```
cd mainnet
sudo bash xdc-attach.sh
```


**For Testnet**

Run:
```
cd testnet
docker compose -f docker-compose.yml up -d
```

You should be able to see your node listed on the [Apothem Network](https://apothem.network/#stats) page.
Select **"Switch to LiveNet"** to check **LiveNetwork** Stats and Select **"Switch to TestNet"** for **TestNetwork.**

Your coinbase address can be found in xdcchain/coinbase.txt file.

To stop the node or if you encounter any issues use:
```
cd testnet
docker compose -f docker-compose.yml down
```

## How to setting RPC
By default, RPC is disabled. To enable RPC, follow these steps:

1. Copy `mainnet/env.example` to `mainnet/.env` (if not already created)
2. In the `.env` file, set:
   ```
   ENABLE_RPC=true
   ```

### Configure RPC Parameters

All RPC-related configurations are located in the `.env` file. You can modify the following parameters as needed:

**RPC API Configuration**

- `RPC_API`: List of RPC APIs (Default: db,eth,net,txpool,web3,XDPoS)
- `RPC_CORS_DOMAIN`: CORS domain settings (Default: \*)
- `RPC_ADDR`: RPC listening address (Default: 0.0.0.0)
- `RPC_PORT`: RPC port (Default: 8545)
- `RPC_VHOSTS`: Virtual host settings (Default: \*)

**WebSocket Configuration**

- `WS_API`: List of WebSocket APIs (Default: db,eth,net,txpool,web3,XDPoS)
- `WS_ADDR`: WebSocket listening address (Default: 0.0.0.0)
- `WS_ORIGINS`: Allowed WebSocket origins (Default: \*)
- `WS_PORT`: WebSocket port (Default: 8546)


## Troubleshooting


Public discussions on the technical issues, post articles and request for Enhancements and Technical Contributions.

- [Discord](https://discord.com/invite/KZdD6pkFxp)
- [Telegram](https://t.me/xinfintalk)
- [X (Twitter)](https://x.com/XDCNetwork)
- [Reddit](https://www.reddit.com/r/xinfin/)
- [GitHub](https://github.com/XinFinorg)
- [XinFin FAQs](https://xinfin.org/faqs)
