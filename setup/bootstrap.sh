#!/bin/bash

set -euo pipefail


function configureXinFinNode(){
    read -r -p "Please enter your XinFin Network (mainnet/testnet/devnet) :- " Network

    if [ "${Network}" != "mainnet" ] && [ "${Network}" != "testnet" ] && [ "${Network}" != "devnet" ]; then
            echo "The network ${Network} is not one of mainnet/testnet/devnet. Please check your spelling."
            return
    fi
    echo "Your running network is ${Network}"
    echo ""

    read -r -p "Please enter your XinFin MasterNode Name :- " MasterNodeName
    echo "Your Masternode Name is ${MasterNodeName}"
    echo ""
    
    echo "Generate new private key and wallet address."
    echo "If you have your own key, you can change after this and restart the node"

    read -r -p "Type 'Y' or 'y' to continue: " ans

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

    # Install Docker Engine 24.0+ which includes Docker Compose v2
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    sleep 5
    echo "Docker and Docker Compose v2 installed successfully"

    echo "Clone Xinfin Node"
    git clone https://github.com/XinFinOrg/XinFin-Node || exit 1
    cd "XinFin-Node/$Network" || exit 1

    if [ ! -f env.example ]; then
        echo "Environment template not found: $(pwd)/env.example"
        exit 1
    fi
    install -m 600 env.example .env
    
    echo "Generating Private Key and Wallet Address into keys.json"
    docker build -t address-creator ../address-creator/
    docker run -e NUMBER_OF_KEYS=1 -e FILE=true -v "$(pwd):/work/output" -it address-creator

    chmod 600 keys.json
    PRIVATE_KEY=$(jq -er '.key0.PrivateKey // empty' keys.json)
    rm -f keys.json
    sed -i "s/PRIVATE_KEY=xxxx/PRIVATE_KEY=${PRIVATE_KEY}/g" .env

    case "${Network}" in
        mainnet) node_name_variable="INSTANCE_NAME" ;;
        testnet) node_name_variable="NODE_NAME" ;;
        *)
            echo "Unsupported network: ${Network}"
            exit 1
            ;;
    esac
    escaped_master_node_name=$(printf '%s' "${MasterNodeName}" | sed 's/[\/&|\\]/\\&/g')
    sed -i "s|^${node_name_variable}=.*|${node_name_variable}=${escaped_master_node_name}|" .env

    echo ""
    echo "Starting Xinfin Node ..."
    docker compose -f docker-compose.yml up --build --force-recreate -d
}

function main(){

    configureXinFinNode
    
}

main
