const { profile } = require('console');
const fs = require('fs');
const yaml = require('js-yaml');
const { exit } = require('process');
const crypto = require('crypto');
const readline = require('readline')
const reader = require("readline-sync");
const ethers = require('ethers');
const config = require('./gen_config')
Object.freeze(config)
// console.log(config)


const num_machines = config.num_machines
const num_subnet = config.num_subnet
const ip_1 = config.ip_1
const network_name = config.network_name
const network_id = config.network_id
const secret_string = config.secret_string
const output_path = `${__dirname}/../generated/`


num_per_machine = Array(num_machines)
//integer division
for (let i=0; i<num_machines; i++){
  num_per_machine[i] = Math.floor(num_subnet / num_machines) 
}
//divide up the remainder
for (let i=0; i<num_subnet%num_machines; i++) {   
  num_per_machine[i]++
}
num_per_machine.reverse()  //let first machines host services, put fewer subnets

//gen docker-compose
doc = {
  'version': '3.7',
  'services': {
  }
}

start_num = 1
for (let i=1; i<=num_machines; i++){
  subnet_nodes = genSubnetNodes(machine_id=i, num=num_per_machine[i-1], start_num=start_num)
  start_num+=num_per_machine[i-1]
  Object.entries(subnet_nodes).forEach(entry => {
    const [key, value] = entry;
    doc['services'][key]=value
  });
}

//gen subnets configs
subnet_services = genServices(machine_id=1)
Object.entries(subnet_services).forEach(entry => {
  const [key, value] = entry;
  doc['services'][key]=value
});

compose_content = yaml.dump(doc, {
})

//gen services configs
commonconf = genServicesConfig(ip_1, secret=secret_string)

keys = genSubnetKeys()            

subnetconf=[]
for (let i=1; i<=num_subnet; i++){
  subnetconf.push(genSubnetConfig(i, keys, ip_1, network_id, secret))
}
compose_conf = genComposeEnv()

//checkpoint smartcontract deployment config
deployment_json = genDeploymentJson(keys)

//deployment commands list 
commands = genCommands(num_machines, network_name, network_id, num_subnet, keys)
genesis_input = genGenesisInputFile(network_name, network_id, num_subnet, keys)
genesis_input_file = yaml.dump(genesis_input, {})

//writing files
// fs.rmSync(`${output_path}`, { recursive: true, force: true }); //wont work with docker mount
// fs.mkdirSync(`${output_path}`) //won't work with docker mount
fs.writeFile(`${output_path}/placeholder.txt`, '-', err => {
  if (err) {
    console.error(err);
    exit()
  }
});

fs.writeFile(`${output_path}/docker-compose.yml`, compose_content, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

fs.writeFileSync(`${output_path}/common.env`, commonconf, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

keys_json = JSON.stringify(keys, null, 2);
fs.writeFile(`${output_path}/keys.json`, keys_json, (err) => {
    if (err) {
      console.error('Error writing key file:', err);
      exit()
    }
});

for (let i=1; i<=num_subnet; i++){
  fs.writeFileSync(`${output_path}/subnet${i}.env`, subnetconf[i-1], err => {
    if (err) {
      console.error(err);
      exit()
    }
    })
}

fs.writeFile(`${output_path}/docker-compose.env`, compose_conf, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

deployment_json = JSON.stringify(deployment_json, null, 2);
fs.writeFile(`${output_path}/deployment.config.json`, deployment_json, (err) => {
  if (err) {
    console.error('Error writing file:', err);
    exit()
  }
})

fs.writeFile(`${output_path}/genesis_input.yml`, genesis_input_file, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

fs.writeFile(`${output_path}/commands.txt`, commands, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

console.log('gen successful, follow the instructions in command.txt')


function genSubnetNodes(machine_id, num, start_num=1) {
  subnet_nodes = {}
  for (let i=start_num; i < start_num+num; i++) {
    node_name='subnet'+i.toString()
    volume='./xdcchain'+i.toString()+':/work/xdcchain'
    var config_path='${SUBNET_CONFIG_PATH}/subnet'+i.toString()+'.env'
    compose_profile='machine'+machine_id.toString()
    subnet_nodes[node_name] = {
      'image': `xinfinorg/xdcsubnets:${config.version.subnet}`,
      'volumes': [volume, '${SUBNET_CONFIG_PATH}/genesis.json:/work/genesis.json'],
      'restart': 'always',
      'network_mode': 'host',
      'env_file': [config_path],
      'profiles': [compose_profile]
    }

  }
  return subnet_nodes
}

function genBootNode(machine_id){
  var config_path='${SUBNET_CONFIG_PATH}/common.env'
  machine='machine'+machine_id.toString()
  bootnode = {
    'image': `xinfinorg/xdcsubnets:${config.version.bootnode}`,
    'restart': 'always',
    'env_file': config_path,
    'volumes': ['./bootnodes:/work/bootnodes'],
    'entrypoint': ['bash','/work/start-bootnode.sh'],
    'command': ['-verbosity', '6', '-nodekey', 'bootnode.key'],
    'ports': ['20301:20301/tcp','20301:20301/udp'],
    'profiles': [machine]
  }
  return bootnode
}

function genObserver(machine_id){
  var config_path='${SUBNET_CONFIG_PATH}/common.env'
  machine='machine'+machine_id.toString()
  observer = {    
    'image': `xinfinorg/devnet:${config.version.observer}`,
    'restart': 'always',
    'env_file': config_path,
    'ports': ['20302:30303', '7545:8545', '7555:8555'],
    'profiles': [machine]
  }
  return observer
}

function genServices(machine_id) {
  var config_path='${SUBNET_CONFIG_PATH}/common.env'
  machine='services'
  frontend = {
    'image': `xinfinorg/subnet-frontend:${config.version.frontend}`,    
    'restart': 'always',
    'volumes': [`${config_path}:/app/.env.local`],
    'ports': ['5000:5000'],
    'profiles': [machine]
  }
  relayer = {
    'image': `xinfinorg/xdc-relayer:${config.version.relayer}`,
    'restart': 'always',
    'env_file': config_path,
    'profiles': [machine]
  }
  stats = {
    'image': `xinfinorg/subnet-stats-service:${config.version.stats}`,
    'restart': 'always',
    'env_file': config_path,
    'volumes': ['./stats-service/logs:/app/logs'],
    'ports': ['3000:3000'],
    'profiles': [machine]
  },

  bootnode=genBootNode(machine_id),
  observer=genObserver(machine_id),      


  services = {
    'bootnode': bootnode,
    // 'observer': observer,                 //disable until we comeup with a satisfied solution
    'relayer': relayer,
    'stats': stats,
    'frontend': frontend,
  }

  return services
}

function genSubnetConfig(subnet_id, key, ip_1, network_id, secret){
  key_name = `key${subnet_id}`
  private_key = key[key_name]['PrivateKey']
  port = 20303+subnet_id-1
  rpcport = 8545+subnet_id-1
  wsport= 9555+subnet_id-1
  var config_env = `
INSTANCE_NAME=subnet${subnet_id}
PRIVATE_KEY=${private_key}
BOOTNODES=enode://cc566d1033f21c7eb0eb9f403bb651f3949b5f63b40683917\
765c343f9c0c596e9cd021e2e8416908cbc3ab7d6f6671a83c85f7b121c1872f8be\
50a591723a5d@${ip_1}:20301
NETWORK_ID=${network_id}
SYNC_MODE=full
RPC_API=admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS
STATS_SERVICE_ADDRESS=${ip_1}:3000
STATS_SECRET=${secret}
PORT=${port}
RPCPORT=${rpcport}
WSPORT=${wsport}
LOG_LEVEL=2
`

return config_env
}

function genServicesConfig(ip_1, secret){
  var url = ''
  switch (config.parentchain.network){
    case 'devnet':
      url='https://devnetstats.apothem.network/devnet'  
      break
    case 'testnet':
      url='https://devnetstats.apothem.network/testnet' //confirm url
      break
    case 'mainnet':
      url='https://devnetstats.apothem.network/mainnet' //confirm url
      break
    default: 
      console.error('PARENTCHAIN invalid, should be devnet, testnet, or mainnet') //should not reach this case
      exit()
  }
  
  var config_env=`
# Bootnode
EXTIP=${ip_1}
BOOTNODE_PORT=20301

# Stats and relayer
#PARENTCHAIN_URL=http://${ip_1}:9555
PARENTCHAIN_URL=${url}
PARENTCHAIN_WALLET=${config.parentchain.pubkey}
PARENTCHAIN_WALLET_PK=${config.parentchain.privatekey}
SUBNET_URL=http://${ip_1}:8545
RELAYER_MODE=${config.relayer_mode}
CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
SLACK_WEBHOOK=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
CORS_ALLOW_ORIGIN=*

# Parent Chain Observe Node
PARENTCHAIN_NODE_NAME=mainnet_observer
PRIVATE_KEYS=1111111111111111111111111111111111111111111111111111111111111111

# Frontend
VITE_SUBNET_URL=http://${ip_1}:3000

# Share Variable
STATS_SECRET=${secret}
`
  return config_env
}

// function genSubnetKeys(){
//   num = config.num_subnet
//   const keys = {}
//   for ( let i = 1; i <= num+1; i++) {
//       const key = `key${i}`
//       const privateKey = crypto.randomBytes(32).toString('hex');
//       const wallet = new ethers.Wallet(privateKey);
//       if (i==num+1){
//         keys['Grandmaster'] = {
//           "PrivateKey": privateKey,
//           "0x":wallet.address,
//           "xdc": wallet.address.replace(/^0x/i, "xdc"),
//           "short": wallet.address.replace(/^0x/i, '')
//         }

//       }else{
//         keys[key] = {
//             "PrivateKey": privateKey,
//             "0x":wallet.address,
//             "xdc": wallet.address.replace(/^0x/i, "xdc"),
//             "short": wallet.address.replace(/^0x/i, '')
//       }
//     }
//   }
//   return keys
// }

function genSubnetKeys(){
  const keys = {}
  num = config.keys.subnets_addr.length
  for(i=0; i<config.keys.subnets_addr.length; i++){
    const key = `key${i+1}`
    const private_key = config.keys.subnets_pk[i]
    const address = config.keys.subnets_addr[i]
    keys[key] = {
      "PrivateKey": private_key,
      "0x": address,
      "xdc": address.replace(/^0x/i, "xdc"),
      "short": address.replace(/^0x/i, '')
    }
  }
  keys['Grandmaster'] = {
    "PrivateKey": config.keys.grandmaster_pk,
    "0x": config.keys.grandmaster_addr,
    "xdc": config.keys.grandmaster_addr.replace(/^0x/i, "xdc"),
    "short": config.keys.grandmaster_addr.replace(/^0x/i, '')
  }

  if (Object.keys(keys).length != config.num_subnet+1){      //sanity check
    console.log('bad case, key length not equal number of subnets')
    console.log(Object.keys(keys).length, config.num_subnet+1)
    console.log(keys)
    exit()
  }

  return keys
}


function genDeploymentJson(keys){
  num = Object.keys(keys).length-1;
  validators = []
  for (let i=1; i<= num; i++){
    key_name = `key${i}`
    public_key = keys[key_name]['0x']
    validators.push(public_key)
  }

  deployment = {
    "validators": validators,
    "gap": 450,
    "epoch": 900,
    "xdcparentnet": "https://devnetstats.apothem.network/devnet",
    // "xdcparentnet": "http://127.0.0.1:20302", 
    // "xdcsubnet": "http://127.0.0.1:8545" 
    "xdcsubnet": `http://${ip_1}:8545`
  }
  return deployment

}

function genCommands(num_machines, network_name, network_id, num_subnet, keys){
  conf_path = __dirname+'/config/'
  set_env='SUBNET_CONFIG_PATH='+conf_path
  var commands=''

  for(let i=1; i <= num_machines; i++){
    machine_name = 'machine'+i.toString()
    commands+=machine_name+`:                deploy subnet on machine${i}\n`
    // commands+=`  docker-compose up -d --profile ${machine_name} -e ${set_env} \n`
    if (i!=1){
      commands+=`  Prerequisite: copy docker-compose.yml,docker-compose.env,config/subnetX.env to ${machine_name}. Make sure docker-compose.env points to subnetX.env directory.\n`
    }
    commands+=`  docker compose --env-file docker-compose.env --profile ${machine_name} pull\n`
    commands+=`  docker compose --env-file docker-compose.env --profile ${machine_name} up -d\n\n` //composeV2
  }
                                    
  commands+=`\nmachine1:                deploy checkpoint smart contract (please be mindful of docker image tag if you are not using 'latest')\n` // 
  commands+=`  cd ..\n`
  commands+=`  docker run --env-file generated/common.env \\
    -v $(pwd)/generated/:/app/generated/ \\
    --entrypoint 'bash' ${config.docker_image_name} ./deploy_csc.sh \n`       
  // commands+=`  make an edit to ./config/common.env to include values for CHECKPOINT_CONTRACT \n`
  commands+=`  cd generated\n`
  commands+=`\nmachine1:                start services and frontend\n`
  commands+=`  docker compose --env-file docker-compose.env --profile services pull\n`
  commands+=`  docker compose --env-file docker-compose.env --profile services up -d\n`
  return commands
}

function genComposeEnv(){
  conf_path = `SUBNET_CONFIG_PATH=${config.deployment_path}/generated/`
  return conf_path
}

// function genGenesisInstructions(network_name, network_id, num_subnet, keys, indent){
//   // random_key = genSubnetKeys(1)['key1']['short']
//   questions = []
//   commands = []
//   questions.push('')
//   commands.push(`${network_name}`)     //name
//   questions.push('')
//   commands.push(`2`) //
//   questions.push('')
//   commands.push(`3`)  //
//   questions.push('')
//   commands.push('default') //blocks second
//   questions.push('')
//   commands.push('default')  //ethers reward
//   questions.push('')
//   commands.push('default')  //v2blocknum
//   questions.push('')
//   commands.push('default')  //v2timeout
//   questions.push('')
//   commands.push('default')  //v2timeout
//   questions.push('')
//   commands.push(Math.ceil(((2/3)*num_subnet)).toString()) //num votes to generate QC
//   questions.push('')
//   commands.push(keys['Grandmaster']['short']) //who owns first masternode
//   questions.push('')
//   commands.push(keys['Grandmaster']['short']) //grandmaster nodes 
  
//   num = Object.keys(keys).length-1;
//   key_string = []
//   for (let i=1; i<= num; i++){
//     key_name = `key${i}`
//     public_key = keys[key_name]['short']
//     key_string.push(public_key)
//   }
//   join_str='\n'+indent
//   key_string = key_string.join(join_str)
//   questions.push('')
//   commands.push(key_string) //master nodes 
//   questions.push('')
//   commands.push('default') //blocks per epoch
//   questions.push('')
//   commands.push('default') //gap block
//   questions.push('')
//   commands.push(keys['Grandmaster']['short']) //foundation wallet address
//   questions.push('')
//   commands.push('1111111111111111111111111111111111111111')//Which accounts are allowed to confirm in Foudation MultiSignWallet?
//   questions.push('')
//   commands.push('default')  //How many require for confirm tx in Foudation MultiSignWallet? 
//   questions.push('')
//   commands.push('1111111111111111111111111111111111111111') //Which accounts are allowed to confirm in Team MultiSignWallet?
//   questions.push('')
//   commands.push('default')  //How many require for confirm tx in Team MultiSignWallet?
//   questions.push('')
//   commands.push('1111111111111111111111111111111111111111') //What is swap wallet address for fund 55m XDC?
//   questions.push('')
//   commands.push(keys['Grandmaster']['short']) //Which accounts should be pre-funded? 
//   questions.push('')
//   commands.push(`${network_id}`) //final input network_id
  
//   return commands
// }

function genGenesisInputFile(network_name, network_id,  num_subnet, keys ){
// name: localNet
// certthreshold: 2
// grandmasters: 
//   - "0x30f21E514A66732DA5Dff95340624fa808048601"
// masternodes:
//   - "0x25b4cbb9a7ae13feadc3e9f29909833d19d16de5"
//   - "0x3d9fd0c76bb8b3b4929ca861d167f3e05926cb68"
//   - "0x3c03a0abac1da8f2f419a59afe1c125f90b506c5"
// chainid: 29412

  var masternodes = []
  var grandmasters = []
  Object.keys(keys).forEach(function(k) {
    var v = keys[k];
    if (k == 'Grandmaster'){
      grandmasters.push(v['0x'])
    } else {
      masternodes.push(v['0x'])
    }
  });

  var config = {
    "name": network_name,
    "certthreshold": Math.ceil(((2/3)*num_subnet)),
    "grandmasters": grandmasters,
    "masternodes": masternodes,
    "chainid": network_id,
  }
  return config
}

