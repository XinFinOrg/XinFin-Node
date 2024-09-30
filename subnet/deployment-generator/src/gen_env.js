const config = require("./config_gen");
Object.freeze(config);

module.exports = {
  genSubnetConfig,
  genSubnetConfigMac,
  genServicesConfig,
  genServicesConfigMac,
  genContractDeployEnv,
  genContractDeployEnvMac,
};

function genSubnetConfig(subnet_id, key) {
  const key_name = `key${subnet_id}`;
  let private_key = key[key_name]["PrivateKey"];
  private_key = private_key.slice(2, private_key.length); // remove 0x for subnet conf
  const port = 20303 + subnet_id - 1;
  const rpcport = 8545 + subnet_id - 1;
  const wsport = 9555 + subnet_id - 1;
  const config_env = `
INSTANCE_NAME=subnet${subnet_id}
PRIVATE_KEY=${private_key}
BOOTNODES=enode://cc566d1033f21c7eb0eb9f403bb651f3949b5f63b40683917\
765c343f9c0c596e9cd021e2e8416908cbc3ab7d6f6671a83c85f7b121c1872f8be\
50a591723a5d@${config.ip_1}:20301
NETWORK_ID=${config.network_id}
SYNC_MODE=full
RPC_API=db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS
STATS_SERVICE_ADDRESS=${config.ip_1}:5213
STATS_SECRET=${config.secret_string}
PORT=${port}
RPCPORT=${rpcport}
WSPORT=${wsport}
LOG_LEVEL=2
`;

  return config_env;
}

function genSubnetConfigMac(subnet_id, key, ip_record) {
  const key_name = `key${subnet_id}`;
  let private_key = key[key_name]["PrivateKey"];
  private_key = private_key.slice(2, private_key.length); // remove 0x for subnet conf
  const port = 20303 + subnet_id - 1;
  const rpcport = 8545 + subnet_id - 1;
  const wsport = 9555 + subnet_id - 1;
  const config_env = `
INSTANCE_NAME=subnet${subnet_id}
PRIVATE_KEY=${private_key}
BOOTNODES=enode://cc566d1033f21c7eb0eb9f403bb651f3949b5f63b40683917\
765c343f9c0c596e9cd021e2e8416908cbc3ab7d6f6671a83c85f7b121c1872f8be\
50a591723a5d@${ip_record["bootnode"]}:20301
NETWORK_ID=${config.network_id}
SYNC_MODE=full
RPC_API=db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS
STATS_SERVICE_ADDRESS=${ip_record["stats"]}:5213
STATS_SECRET=${config.secret_string}
PORT=${port}
RPCPORT=${rpcport}
WSPORT=${wsport}
LOG_LEVEL=2
`;

  return config_env;
}

function genServicesConfig() {
  const url = config.parentnet.url;
  let config_env = `
# Bootnode
EXTIP=${config.ip_1}
BOOTNODE_PORT=20301

# Stats and relayer
PARENTNET_URL=${url}
PARENTNET_WALLET=${config.parentnet.pubkey}
SUBNET_URL=http://${config.ip_1}:8545
RELAYER_MODE=${config.relayer_mode}
SLACK_WEBHOOK=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
CORS_ALLOW_ORIGIN=*

# Frontend 
VITE_SUBNET_URL=http://${config.public_ip}:5213
VITE_SUBNET_RPC=http://${config.public_ip}:8545

# Share Variable
STATS_SECRET=${config.secret_string}

# CSC
CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
PARENTNET_WALLET_PK=${config.parentnet.privatekey}

`;

if (config.zero.zero_mode == 'one-directional'){
  config_env += `
# # XDC-ZERO. It's optional. Don't uncomment it if not planning to enable it
# SUBNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_WALLET_PK=${config.zero.parentnet_zero_wallet_pk}
  `

} else if (config.zero.zero_mode == 'bi-directional'){
  config_env += `
# # XDC-ZERO. It's optional. Don't uncomment it if not planning to enable it
# SUBNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_WALLET_PK=${config.zero.parentnet_zero_wallet_pk}

# # Reverse-XDC-ZERO. optional.
# REVERSE_CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
# SUBNET_WALLET_PK=${config.zero.subnet_wallet_pk}
# SUBNET_ZERO_WALLET_PK=${config.zero.subnet_zero_wallet_pk}
  `
}
  // # Parent Chain Observe Node
  // PARENTNET_NODE_NAME=mainnet_observer
  // PRIVATE_KEYS=11111111111111111111111111111111111111111111111111111111111111
  return config_env;
}

function genServicesConfigMac(ip_record) {
  const url = config.parentnet.url;
  let config_env = `
# Bootnode
EXTIP=${ip_record["bootnode"]}
BOOTNODE_PORT=20301

# Stats and relayer
PARENTNET_URL=${url}
PARENTNET_WALLET=${config.parentnet.pubkey}
SUBNET_URL=http://${ip_record["subnet1"]}:8545
RELAYER_MODE=${config.relayer_mode}
SLACK_WEBHOOK=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
CORS_ALLOW_ORIGIN=*

# Frontend
VITE_SUBNET_URL=http://127.0.0.1:5213
VITE_SUBNET_RPC=http://127.0.0.1:8545

# Share Variable
STATS_SECRET=${config.secret_string}

# CSC
CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
PARENTNET_WALLET_PK=${config.parentnet.privatekey}

`;
if (config.zero.zero_mode == 'one-directional'){
  config_env += `
# # XDC-ZERO. It's optional. Don't uncomment it if not planning to enable it
# SUBNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_WALLET_PK=${config.zero.parentnet_zero_wallet_pk}
  `

} else if (config.zero.zero_mode == 'bi-directional'){
  config_env += `
# # XDC-ZERO. It's optional. Don't uncomment it if not planning to enable it
# SUBNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_WALLET_PK=${config.zero.parentnet_zero_wallet_pk}

# # Reverse-XDC-ZERO. optional.
# REVERSE_CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
# SUBNET_WALLET_PK=${config.zero.subnet_wallet_pk}
# SUBNET_ZERO_WALLET_PK=${config.zero.subnet_zero_wallet_pk}
  `
}
  return config_env;
}

function genContractDeployEnvMac() {
  const config_deploy = `
PARENTNET_URL=${config.parentnet.url}
SUBNET_URL=http://${ip_record["subnet1"]}:8545

PARENTNET_PK=${config.parentnet.privatekey}
SUBNET_PK=${config.keys.grandmaster_pk}

CSC=0x0000000000000000000000000000000000000000
REVERSE_CSC=0x0000000000000000000000000000000000000000

# # For Subswap deployment. It's optional.
# SUBNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# SUBNET_APP=0x0000000000000000000000000000000000000000
# PARENTNET_APP=0x0000000000000000000000000000000000000000
`;
  return config_deploy;
}

function genContractDeployEnv() {
  const config_deploy = `
PARENTNET_URL=${config.parentnet.url}
SUBNET_URL=http://${config.ip_1}:8545


PARENTNET_PK=${config.parentnet.privatekey}
SUBNET_PK=${config.keys.grandmaster_pk}

CSC=0x0000000000000000000000000000000000000000
REVERSE_CSC=0x0000000000000000000000000000000000000000

# # For Subswap deployment. It's optional.
# SUBNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# PARENTNET_ZERO_CONTRACT=0x0000000000000000000000000000000000000000
# SUBNET_APP=0x0000000000000000000000000000000000000000
# PARENTNET_APP=0x0000000000000000000000000000000000000000
`;
  return config_deploy;
}
