
## XinFin XDC Testnet

## Prerequisite
**Operating System**: Ubuntu 16.04 64-bit or higher

Should be facing internet directly with **public IP** & **without NAT**

**Tools**: Docker, Docker Compose


## Network Ports

Following network ports need to be open for the nodes to communicate

| Port | Type | Definition |
|:------:|:-----:|:---------- |
|8545| TCP | RPC |
|30303| TCP/UDP | XDC |

### Setup

## Clone repository
```
git clone https://github.com/XinFinOrg/XinFin-Node.git
```

Enter `XinFin-Node` directory
```
cd XinFin-Node
```


## Step: 1 Install docker & docker-compose
    sudo ./install_docker.sh

## Step: 2 Update .env file with details
Create `.env` file by using the sample - `.env.example`

Enter your node name in the INSTANCE_NAME field.

Enter your email address in CONTACT_DETAILS field.


## Step: 3 Start your Node

Run:
```
sudo docker-compose -f docker-services.yml up -d
```

You should be able to see your node listed on this page: [http://stats.testnet.xinfin.network:3001/](http://stats.testnet.xinfin.network:3001/)

