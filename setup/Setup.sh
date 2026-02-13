#!/bin/bash


function configureXinFinNode(){
    echo "Installing Git"

    sudo apt-get update

    sudo apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            git \
            software-properties-common -y

    echo "Clone Xinfin Node"

    git clone https://github.com/XinFinOrg/XinFin-Node && cd XinFin-Node

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
}

function init(){
        configureXinFinNode
}


function main(){
    init
}

main
