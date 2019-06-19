
## How to Setup XinFin-XDC Masternode (One click Installer)

**Operating System**: Ubuntu 16.04 64-bit or higher (Scroll Down for Windows and MAC Operating System)

Should be facing internet directly with **public IP** & **without NAT**

## Network Ports

Following network ports need to be open for the nodes to communicate

| Port | Type | Definition |
|:------:|:-----:|:---------- |
|8545| TCP | RPC |
|30303| TCP/UDP | XDC |


###  Download XinFin One Click Installer (to setup Masternode) for Windows, Linux and mac OS ###

[One Click Masternode Installer for Windows OS (64-bit)](http://download.xinfin.network/XinFin-Network-installer-0-12-0.exe)

[One Click Masternode Installer for Linux OS](http://download.xinfin.network/XinFin-Network-linux64-0-12-0.deb)

[One Click Masternode Installer for macOS](http://download.xinfin.network/XinFin-Network-installer-0-12-0.rar)


# Masternode Tools and Public Community Channel #

Community Forum update link: http://xinfin.net

Telegram Development Community: https://t.me/XinFinDevelopers

Slack Public Channel: https://xinfin-public.slack.com/messages/CELR2M831/



## Setup XinFin Masternode Method 2 ##

**Operating System**: Ubuntu 16.04 64-bit or higher (Scroll Down for Windows and MAC Operating System)

Should be facing internet directly with **public IP** & **without NAT**

**Tools**: Docker, Docker Compose(1.21.2+)

Setup (For Ubuntu 16.04 64-bit or higher Operating System) 

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

Enter either your company or product name in the INSTANCE_NAME field.

Enter your email address in CONTACT_DETAILS field.

```
cp env.example .env
nano .env
```

## Step: 3 Start your Node

**For Mainnet**

Run:
```
sudo docker-compose -f docker-services.yml up -d
```

You should be able to see your node listed on this page: [https://xinfin.network](https://XinFin.network/) Select Menu "Switch to TestNet" for TestNetwork and Select "Switch to LiveNet" to check LiveNetwork Stats. 

Your coinbase address can be found in xdcchain/coinbase.txt file.

To stop the node or if you encounter any issues use::
```
sudo docker-compose -f docker-services.yml down
```

**For Testnet**

Run:
```
sudo docker-compose -f apothem-network.yml up -d
```

You should be able to see your node listed on this page: [https://apothem.network] Select "Switch to LiveNet" to check LiveNetwork Stats and Select "Switch to TestNet" for TestNetwork.

Your coinbase address can be found in xdcchain/coinbase.txt file.

To stop the node or if you encounter any issues use::
```
sudo docker-compose -f apothem-network.yml down
```

**Troubleshooting**

Public discussions on the technical issues, post articles and request for Enhancements and Technical Contributions. 

[Slack Public Chat](https://launchpass.com/xinfin-public), 

[Telegram Chat](http://bit.do/Telegram-XinFinDev), 

[Forum](https://xinfin.net), 

[GitHub](https://github.com/XinFinorg)


