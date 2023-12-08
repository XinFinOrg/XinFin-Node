
const config = require('./config_gen')
Object.freeze(config)

module.exports = { 
  genSubnetConfig,
  genSubnetConfigMac,
  genServicesConfig,
  genServicesConfigMac,
}



function genSubnetConfig(subnet_id, key){
  key_name = `key${subnet_id}`
  private_key = key[key_name]['PrivateKey']
  private_key = private_key.slice(2, private_key.length)    //remove 0x for subnet conf
  port = 20303+subnet_id-1
  rpcport = 8545+subnet_id-1
  wsport= 9555+subnet_id-1
  var config_env = `
INSTANCE_NAME=subnet${subnet_id}
PRIVATE_KEY=${private_key}
BOOTNODES=enode://cc566d1033f21c7eb0eb9f403bb651f3949b5f63b40683917\
765c343f9c0c596e9cd021e2e8416908cbc3ab7d6f6671a83c85f7b121c1872f8be\
50a591723a5d@${config.ip_1}:20301
NETWORK_ID=${config.network_id}
SYNC_MODE=full
RPC_API=admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS
STATS_SERVICE_ADDRESS=${config.ip_1}:3000
STATS_SECRET=${config.secret_string}
PORT=${port}
RPCPORT=${rpcport}
WSPORT=${wsport}
LOG_LEVEL=2
`

return  config_env
}

function genSubnetConfigMac(subnet_id, key, ip_record){
  key_name = `key${subnet_id}`
  private_key = key[key_name]['PrivateKey']
  private_key = private_key.slice(2, private_key.length)    //remove 0x for subnet conf
  port = 20303+subnet_id-1
  rpcport = 8545+subnet_id-1
  wsport= 9555+subnet_id-1
  var config_env = `
INSTANCE_NAME=subnet${subnet_id}
PRIVATE_KEY=${private_key}
BOOTNODES=enode://cc566d1033f21c7eb0eb9f403bb651f3949b5f63b40683917\
765c343f9c0c596e9cd021e2e8416908cbc3ab7d6f6671a83c85f7b121c1872f8be\
50a591723a5d@${ip_record["bootnode"]}:20301
NETWORK_ID=${config.network_id}
SYNC_MODE=full
RPC_API=admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS
STATS_SERVICE_ADDRESS=${ip_record["stats"]}:3000
STATS_SECRET=${config.secret_string}
PORT=${port}
RPCPORT=${rpcport}
WSPORT=${wsport}
LOG_LEVEL=2
`

return config_env
}

function genServicesConfig(){
  var url = ''
  switch (config.parentnet.network){
    case 'devnet':
      url='https://devnetstats.apothem.network/devnet'  
      break
    case 'testnet':
      url='https://erpc.apothem.network/' 
      break
    case 'mainnet':
      url='https://devnetstats.apothem.network/mainnet' //confirm url
      break
    default: 
      console.error('PARENTNET invalid, should be devnet, testnet, or mainnet') //should not reach this case
      exit()
  }
  
  var config_env=`
# Bootnode
EXTIP=${config.ip_1}
BOOTNODE_PORT=20301

# Stats and relayer
PARENTNET_URL=${url}
PARENTNET_WALLET=${config.parentnet.pubkey}
PARENTNET_WALLET_PK=${config.parentnet.privatekey}
SUBNET_URL=http://${config.ip_1}:8545
RELAYER_MODE=${config.relayer_mode}
CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
SLACK_WEBHOOK=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
CORS_ALLOW_ORIGIN=*

# Frontend
VITE_SUBNET_URL=http://${config.ip_1}:3000

# Share Variable
STATS_SECRET=${config.secret_string}
`
// # Parent Chain Observe Node
// PARENTNET_NODE_NAME=mainnet_observer
// PRIVATE_KEYS=11111111111111111111111111111111111111111111111111111111111111

  return config_env
}

function genServicesConfigMac(ip_record){
  var url = ''
  switch (config.parentnet.network){
    case 'devnet':
      url='https://devnetstats.apothem.network/devnet'  
      break
    case 'testnet':
      url='https://erpc.apothem.network/' 
      break
    case 'mainnet':
      url='https://devnetstats.apothem.network/mainnet' //confirm url
      break
    default: 
      console.error('PARENTNET invalid, should be devnet, testnet, or mainnet') //should not reach this case
      exit()
  }
  
  var config_env=`
# Bootnode
EXTIP=${ip_record["bootnode"]}
BOOTNODE_PORT=20301

# Stats and relayer
PARENTNET_URL=${url}
PARENTNET_WALLET=${config.parentnet.pubkey}
PARENTNET_WALLET_PK=${config.parentnet.privatekey}
SUBNET_URL=http://${ip_record["subnet1"]}:8545
RELAYER_MODE=${config.relayer_mode}
CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
SLACK_WEBHOOK=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
CORS_ALLOW_ORIGIN=*

# Parent Chain Observe Node
PARENTNET_NODE_NAME=mainnet_observer
PRIVATE_KEYS=1111111111111111111111111111111111111111111111111111111111111111

# Frontend
VITE_SUBNET_URL=http://127.0.0.1:3000

# Share Variable
STATS_SECRET=${config.secret_string}
`
  return config_env
}