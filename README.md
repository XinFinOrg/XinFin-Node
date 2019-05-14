
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

## Setup For Windows 64-bit Operating System
```
git clone https://github.com/XinFinOrg/XinFin-Node.git
```

Enter `win64` directory
```
cd XinFin-Node/win64/one-click-installer
```

Run
```
setup.exe
```

This will install the XDC binary in C:\Program Files (x86)\XinFin with all the start-menu, desktop icons & uninstaller.

Righ-click on the XinFin-XDC Masternode icon on desktop & click on "Run as administrator" to launch your masternode.


##  Setup For MAC Operating System (using Vagrant Environments).
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


