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

    configureDockerLogging
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

function init(){
        configureXinFinNode
}


function main(){
    init
}

main
