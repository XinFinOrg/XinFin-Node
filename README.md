## Securing Your XDC Network Node

Before deploying your XDC Network Node, it is critical to secure the server, especially for validator or standby nodes that do not require RPC/WebSocket access. There are two deployment scenarios:

* **RPC Node**: Exposes necessary ports to allow DApps and users to interact with the blockchain.
* **Validator/Standby Node**: Only communicates with the network and should block unnecessary ports for better security.

This guide provides instructions for securing your server, changing the default SSH port, and enabling a firewall for validator/standby nodes.

---

### Initial Server Setup

1. **Log in to your server** using credentials provided by your cloud provider:

   ```bash
   ssh user@your-server-ip
   ```

2. **Update OS packages**:

   ```bash
   sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y
   ```

---

### Setting Up SSH Key Authentication

**Step 1: Generate SSH Key (on your local machine or computer)**

If you don’t already have an SSH key:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

* Save the key in the default path (usually `~/.ssh/id_rsa`)
* You may optionally add a passphrase

**Step 2: Upload the Public Key to the Server**

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub user@your-server-ip
```

**Step 3: Test Login**

```bash
ssh user@your-server-ip
```

**Optional: Disable Password Authentication**

Edit the SSH config file:

```bash
sudo nano /etc/ssh/sshd_config
```

Set the following:

```
PasswordAuthentication no
```

Restart the SSH service:

```bash
sudo systemctl restart ssh
```

Keep your private key (`~/.ssh/id_rsa`) safe. You will need it for all future logins. 
**Do not upload it to the server**

---

### Locking Down Validator/Standby Nodes

If your masternode is being used only for the purpose of maintaining the XDC blockchain and does not require RPC/WebSocket access, the following hardening steps are recommended:

1. Change the default SSH port
2. Block all incoming traffic using a firewall
3. Open only the required ports (30303 for XDC P2P and your new SSH port)

---

### Change the SSH Port

1. Edit the SSH config file:

   ```bash
   sudo nano /etc/ssh/sshd_config
   ```

2. Find the line:

   ```
   #Port 22
   ```

3. Remove the `#` and change `22` to a new custom port (for example, 2222):

   ```
   Port 2222
   ```

4. Save and exit:

   * Press `CTRL+X`, then `Y`, then `ENTER`

5. Restart the SSH service:

   ```bash
   sudo systemctl restart ssh
   ```

To connect from now on:

```bash
ssh -p 2222 user@your-server-ip
```

---

### Configure UFW (Uncomplicated Firewall)

1. **Install UFW**:

   ```bash
   sudo apt install ufw
   ```

2. **Set default policies**:

   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   ```

3. **Allow XDC P2P port**:

   ```bash
   sudo ufw allow 30303
   ```

4. **Allow your SSH port** (replace `2222` with your actual port):

   ```bash
   sudo ufw allow 2222
   ```

5. **Enable UFW**:

   ```bash
   sudo ufw enable
   ```

6. **Reboot the server**:

   ```bash
   reboot
   ```

---

### Testing Access

After rebooting, reconnect to your server using the new SSH port:

```bash
ssh -p 2222 user@your-server-ip
```

If you are unable to connect, use your VPS provider’s web console to access the server and make the necessary firewall or SSH configuration changes.

---

### RPC Node Exception

If you are deploying an RPC node (e.g., for public dApp or API access), you must also allow the following ports:

```bash
sudo ufw allow 8888
sudo ufw allow 8989
```

---

Once your server is secured and accessible, proceed with the standard masternode setup.

---

## How to Setup XinFin Masternode

### Method 1:- Setup XinFin's XDC Masternode One-click Installer ###

To qualify for Masternode on XinFin Network, you need at least **10,000,000 XDC, for the long term.**


**Operating System**:

* Apple Mac
* Windows
* Linux - Ubuntu

**Step 1: Download [XinFin One-Click Installer](https://xinfin.org/setup-masternode) (to setup Masternode) for Windows, Linux, and Mac OS and Install on your local machine.**

**Step 2: Now Run the One Click Installer, Make sure you read the Terms properly then click on I Agree button.**

* **"C:\Program Files\XinFin-Network"** this will be your destination folder and this **"C:\Users\...\AppData\Roaming\XDCChain"** will contain your Keystore folder.
* Make sure, you create a backup of your Keystore folder.
* Now click on "XinFin Network" One click installer.
* You can see the address of One Click Installer in left side, Also you can change the Network.
* For changing the Network, click on "Develop" then select "Network" (XinFin - Main Network/ XinFin Apothem Network)
* You can check the Node status under the **[stats.xinfin.network](http://stats.xinfin.network/)**



https://user-images.githubusercontent.com/92325549/137081568-f1c99c1f-b035-4ef1-8576-04e327056064.mp4



**Step 3: Create a wallet for Masternode**

* Create your wallet address with Mnemonic Phrase or on a hardware wallet. We always recommend to use a hardware wallet for running a Masternode.
* Enter a strong password while creating the wallet.
* **Don't lose your keyphrases**
* **Don't share them with anyone**
* **Always write your a backup or keyphrases and do not store them online.**
* **If you lose them, all your funds will be lost.**
* If you are hosting a Masternode on Testnet then copy the Wallet address and paste it on **[XDC Faucet](https://faucet.apothem.network/)** for the Testnet XDC



https://user-images.githubusercontent.com/92325549/137081588-b644bef6-5b5c-43c6-a703-6459b82db483.mp4



**Step 4: Host your Masternode**

* For hosting the Masternode, you need to log in to your wallet and login the Masternode.
* For uploading the KYC, click on the "Become a Masternode"
* Check the KYC criteria, the KYC file should be in pdf format only.
* Once you upload your KYC, you need to enter the "Coinbase Address" which is in One Click Installer after that click on Apply button.
* Now you will be notify with sucessful toaster i.e **"You have successfully applied for Masternode"**
* You can check all the status regarding your Masternode here: **[master.apothem.network](https://master.apothem.network/)**.




https://user-images.githubusercontent.com/92325549/137086528-4a8c5c44-ce89-4a70-84f6-bc32aac8b681.mp4



---------------------------------

### Method 2 :- Setup XinFin Masternode Bootstrap Script ###

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

### Method 3:- Setup XinFin Masternode Docker ###

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
- [X (Twitter)](https://x.com/XDC_Network_)
- [Reddit](https://www.reddit.com/r/xinfin/)
- [GitHub](https://github.com/XinFinorg)
- [XinFin FAQs](https://xdc.org/resources/faqs)
