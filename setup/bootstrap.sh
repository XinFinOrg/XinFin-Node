#!/bin/bash


function configureXinFinNode(){
    read -p "Please enter your XinFin Network (mainnet/testnet/devnet) :- " Network

    if [ "${Network}" != "mainnet" ] && [ "${Network}" != "testnet" ] && [ "${Network}" != "devnet" ]; then
            echo "The network ${Network} is not one of mainnet/testnet/devnet. Please check your spelling."
            return
    fi
    echo "Your running network is ${Network}"
    echo ""

    read -p "Please enter your XinFin MasterNode Name :- " MasterNodeName
    echo "Your Masternode Name is ${MasterNodeName}"
    echo ""

    echo "Generate new private key and wallet address."
    echo "If you have your own key, you can change after this and restart the node"

    read -p "Type 'Y' or 'y' to continue: " ans

    if [[ "$ans" != [Yy] ]]; then
        echo "Exiting."
        exit 1
    fi

    echo ""
    echo "Installing Git"

    sudo apt-get update
    sudo apt-get install \
            apt-transport-https ca-certificates curl git jq \
            software-properties-common -y

    echo "Installing Docker"

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) \
         stable"

    sudo apt-get update

    sudo apt-get install docker-ce -y

    echo "Installing Docker-Compose"

    curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    chmod +x /usr/local/bin/docker-compose
    sleep 5
    echo "Docker Compose Installed successfully"

    configureDockerLogging

    echo "Clone Xinfin Node"
    git clone https://github.com/XinFinOrg/XinFin-Node && cd XinFin-Node/$Network

    echo "Generating Private Key and Wallet Address into keys.json"
    docker build -t address-creator ../address-creator/ && docker run -e NUMBER_OF_KEYS=1 -e FILE=true -v "$(pwd):/work/output" -it address-creator

    PRIVATE_KEY=$(jq -r '.key0.PrivateKey' keys.json)
    sed -i "s/PRIVATE_KEY=xxxx/PRIVATE_KEY=${PRIVATE_KEY}/g" .env
    sed -i "s/INSTANCE_NAME=XF_MasterNode/INSTANCE_NAME=${MasterNodeName}/g" .env

    echo ""
    echo "Starting Xinfin Node ..."
    sudo docker-compose -f docker-compose.yml up --build --force-recreate -d
}

function main(){

    configureXinFinNode

}

function configureDockerLogging() {
    echo "Configuring Docker log rotation..."

    sudo mkdir -p /etc/docker

    cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
EOF

    echo "Restarting Docker to apply log configuration..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "Docker log configuration applied successfully."
}

main
