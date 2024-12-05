#!/bin/bash

set -eo pipefail

FILE="../docker-compose.yml"

# Detect OS type
OS_TYPE=$(uname)

# Function to handle grep on macOS and Linux differently
grep_command() {
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        grep "$1" "$2"
    else
        grep -oP "$1" "$2"
    fi
}

# Function to handle sed on macOS and Linux differently
sed_command() {
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        sed -i '' "$1" "$2"
    else
        sed -i "$1" "$2"
    fi
}

# Read the current maximum subnet ID (for incrementing)
MAX_SUBNET_ID=$(grep_command 'subnet[0-9]+' "$FILE" | sed 's/subnet//' | sort -n | tail -n 1)

if [ -z "$MAX_SUBNET_ID" ]; then
    NEW_SUBNET_ID=1
else
    NEW_SUBNET_ID=$((MAX_SUBNET_ID + 1))
fi

# Calculate the port numbers and IPv4 address
PORT=$((20302 + NEW_SUBNET_ID))
RPCPORT=$((8544 + NEW_SUBNET_ID))
WSPORT=$((9554 + NEW_SUBNET_ID))
IPV4_ADDRESS=$((10+4 + NEW_SUBNET_ID))

# Function to add new subnet configuration to docker-compose.yml
function  add_docker_compose() {
    # New subnet configuration content
    NEW_SUBNET="\
  subnet$NEW_SUBNET_ID:
    image: xinfinorg/xdcsubnets:v0.3.1
    volumes:
      - ./xdcchain$NEW_SUBNET_ID:/work/xdcchain
      - \${SUBNET_CONFIG_PATH}/genesis.json:/work/genesis.json
    restart: always
    env_file:
      - \${SUBNET_CONFIG_PATH}/subnet$NEW_SUBNET_ID.env
    profiles:
      - machine1
    ports:
      - '$PORT:$PORT'
      - '$RPCPORT:$RPCPORT'
      - '$WSPORT:$WSPORT'
    networks:
      docker_net:
        ipv4_address: 192.168.25.$IPV4_ADDRESS
"

    # Find the "services:" line and insert the new subnet configuration
    awk -v new_subnet="$NEW_SUBNET" '
      BEGIN {found_services=0}
      /services:/ {found_services=1; print ""; print "services:"; print new_subnet; next}
      {print}
    ' "$FILE" > temp_file && mv temp_file "$FILE"

    # Prompt message
    echo "Added new subnet${NEW_SUBNET_ID} configuration to docker-compose.yml!"
}

# Function to create a new .env file and modify its content
function create_new_env_file() {
    read -p "Input private_key: " private_key
    local source_file="../subnet1.env"
    local new_file="../subnet${NEW_SUBNET_ID}.env"

    # Check if the source file exists
    if [ ! -f "$source_file" ]; then
        echo "Source file $source_file does not exist!"
        exit 1
    fi

    # Read the source file content and modify the specified entry
    cp "$source_file" "$new_file"

    # Modify the specified entries
    sed_command "s/^INSTANCE_NAME=.*$/INSTANCE_NAME=${NEW_SUBNET_ID}/" "$new_file"
    sed_command "s/^PRIVATE_KEY=.*$/PRIVATE_KEY=${private_key}/" "$new_file"
    sed_command "s/^PORT=.*$/PORT=${PORT}/" "$new_file"
    sed_command "s/^RPCPORT=.*$/RPCPORT=${RPCPORT}/" "$new_file"
    sed_command "s/^WSPORT=.*$/WSPORT=${WSPORT}/" "$new_file"
    sed_command "s/^LOG_LEVEL=.*$/LOG_LEVEL=2/" "$new_file"

    echo "New subnet${NEW_SUBNET_ID}.env file created!"
}

# Execute functions
add_docker_compose
create_new_env_file
