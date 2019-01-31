
## How to Setup XinFin-XDC Masternode

## Prerequisite

**Operating System**: Ubuntu 16.04 64-bit or higher

Should be facing internet directly with **public IP** & **without NAT**

**Tools**: Docker, Docker Compose(1.21.2+)


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

Enter either your company or product name in the INSTANCE_NAME field.

Enter your email address in CONTACT_DETAILS field.

```
cp env.example .env
nano .env
```

## Step: 3 Start your Node

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

## Upgrade
To upgrade please use the following commands

```
sudo docker-compose -f docker-services.yml down
sudo ./upgrade.sh
sudo docker-compose -f docker-services.yml up -d
```

# Windows/macOS Setup support using Vagrant.
You need to download install below mention 3 Software:
1. Install Oracle [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://www.vagrantup.com/downloads.html)
3. Install [GIT](https://gitforwindows.org/)
    After installation of above 3 Software (this may also need restart of your machine.)
4. Launch "command prompt" & follow the commands below  
   ```sh
    git clone https://github.com/XinFinOrg/XinFin-Node.git
    cd XinFin-Node
    vagrant up
    vagrant ssh
    ```
5. XinFin-Node is automatically copied to /home/vagrant/ follow Step 1, 2 & 3 as explained before in this document to complete the node setup.
6. To shutdown the vagrant instance, run vagrant suspend. To delete it, run vagrant destroy.


**Troubleshooting**

Public discussions on the technical issues, post articles and request for Enhancements and Technical Contributions. 

[Slack Public Chat](https://launchpass.com/xinfin-public), 

[Telegram Chat](http://bit.do/Telegram-XinFinDev), 

[Forum](https://xinfin.net), 

[GitHub](https://github.com/XinFinorg)


