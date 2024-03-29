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

    sudo apt-get install docker-ce -y

    echo "Installing Docker-Compose"
    
    curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        
    chmod +x /usr/local/bin/docker-compose
    sleep 5
    echo "Docker Compose Installed successfully"
}

function init(){
        configureXinFinNode
}


function main(){
    init
}

main
