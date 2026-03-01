#!/bin/bash

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

function installDocker() {
    echo "Installing Docker"

    sudo apt-get update

    sudo apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common -y

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) \
         stable"

    sudo apt-get update

    sudo apt-get install docker-ce -y

    curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose


    chmod +x /usr/local/bin/docker-compose
    sleep 5
    echo "Docker Installed successfully"

    configureDockerLogging
}

function init() {
    if ! command -v docker &> /dev/null; then
        installDocker
    fi
}


function main(){

    init

}

main
