#!/bin/bash

set -eo pipefail
cd "$(dirname "$0")"
FILE="../docker-compose.yml"

# Detect OS type
OS_TYPE=$(uname)

# Function to handle grep on macOS and Linux differently
function grep_command() {
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        grep -oE "$1" "$2"
    else
        grep -oP "$1" "$2"
    fi
}

# Function to handle sed on macOS and Linux differently
function sed_command() {
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
function add_docker_compose_linux() {
    local service_indent=""
    local found_subnet=0
    local subnet_template=""

    # Pick the first subnet entry
    while IFS= read -r line; do
      # Check for services start
      if [[ $line =~ ^[[:space:]]*services: ]]; then
        service_indent=$(echo "$line" | grep -o '^[[:space:]]*')
      fi

      # Check for the first subnet entry
      if [[ $line =~ ^[[:space:]]*subnet[0-9]+: ]]; then
        found_subnet=1
        SUBNET_INDENT=$(echo "$line" | grep -o '^[[:space:]]*')
      fi

      # If in a subnet, save the content as a template
      if [[ $found_subnet -eq 1 ]]; then
        subnet_template+="$line\n"
        if [[ $line =~ ^${SUBNET_INDENT}.*ipv4_address: ]]; then
          found_subnet=0
          break
        fi
      fi
    done < "$FILE"

    # Exit if no subnet is found
    if [[ -z $subnet_template ]]; then
      echo "Error: No subnet entries found in $FILE"
      exit 1
    fi

      # -e "s/subnet[0-9]+/subnet$NEW_SUBNET_ID/" \
    # Modify the template to generate a new entry
    NEW_SUBNET=$(echo -e "$subnet_template" | sed \
      -e "s/subnet[0-9]\+/subnet$NEW_SUBNET_ID/" \
      -e "s/xdcchain[0-9]\+/xdcchain$NEW_SUBNET_ID/" \
      -e "s/2030[0-9]\+:2030[0-9]\+/$PORT:$PORT/" \
      -e "s/854[0-9]\+:854[0-9]\+/$RPCPORT:$RPCPORT/" \
      -e "s/955[0-9]\+:955[0-9]\+/$WSPORT:$WSPORT/" \
      -e "s/192\.168\.25\.[0-9]\+/192.168.25.$IPV4_ADDRESS/")

    # Use sed to insert the new subnet configuration after "services:"
    if grep -q "^services:" "$FILE"; then
      # Escape backslashes and newlines for macOS compatibility
      ESCAPED_SUBNET=$(echo "$NEW_SUBNET" | sed 's/[\/&]/\\&/g' | sed ':a;N;$!ba;s/\n/\\n/g')
      sed_command="/^services:/a \\
$ESCAPED_SUBNET"
      sed -i.bak -e "$sed_command" "$FILE"
      echo "Added new subnet${NEW_SUBNET_ID} configuration to docker-compose.yml!"
    else
      echo "Error: 'services:' not found in $FILE!"
      exit 1
    fi
}

function add_docker_compose_mac() {
    local service_indent=""
    local found_subnet=0
    local subnet_template=""

    # Pick the first subnet entry
    while IFS= read -r line; do
      # Check for services start
      if [[ $line =~ ^[[:space:]]*services: ]]; then
        service_indent=$(echo "$line" | grep -o '^[[:space:]]*')
      fi

      # Check for the first subnet entry
      if [[ $line =~ ^[[:space:]]*subnet[0-9]+: ]]; then
        found_subnet=1
        SUBNET_INDENT=$(echo "$line" | grep -o '^[[:space:]]*')
      fi

      # If in a subnet, save the content as a template
      if [[ $found_subnet -eq 1 ]]; then
        subnet_template+="$line\n"
        if [[ $line =~ ^${SUBNET_INDENT}.*ipv4_address: ]]; then
          found_subnet=0
          break
        fi
      fi
    done < "$FILE"

    # Exit if no subnet is found
    if [[ -z $subnet_template ]]; then
      echo "Error: No subnet entries found in $FILE"
      exit 1
    fi

    # Modify the template to generate a new entry
    NEW_SUBNET=$(echo -e "$subnet_template" | sed -E \
      -e "s/subnet[0-9]+/subnet$NEW_SUBNET_ID/" \
      -e "s/xdcchain[0-9]+/xdcchain$NEW_SUBNET_ID/" \
      -e "s/2030[0-9]+:2030[0-9]+/$PORT:$PORT/" \
      -e "s/854[0-9]+:854[0-9]+/$RPCPORT:$RPCPORT/" \
      -e "s/955[0-9]+:955[0-9]+/$WSPORT:$WSPORT/" \
      -e "s/192.168.25.[0-9]+/192.168.25.$IPV4_ADDRESS/")

    # Use sed to insert the new subnet configuration after "services:"
    if grep -q "^services:" "$FILE"; then
      # Escape backslashes and newlines for macOS compatibility
      ESCAPED_SUBNET=$(echo "$NEW_SUBNET" | sed 's/[\/&]/\\&/g')
      ESCAPED_SUBNET="${ESCAPED_SUBNET//$'\n'/*}*"
      sed_command="/^services:/a\\
$ESCAPED_SUBNET"
      cp ../docker-compose.yml ../docker-compose.yml.bak
      sed -i '' "$sed_command" "$FILE"  
      sed -i '' "s/*/\n/g" "$FILE" 
      echo "Added new subnet${NEW_SUBNET_ID} configuration to docker-compose.yml!"
    else
      echo "Error: 'services:' not found in $FILE!"
      exit 1
    fi
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
if [[ "$OS_TYPE" == "Darwin" ]]; then
    add_docker_compose_mac
else
    add_docker_compose_linux
fi

create_new_env_file
