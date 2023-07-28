const { profile } = require('console');
const fs = require('fs');
const yaml = require('js-yaml');
const { exit } = require('process');
const crypto = require('crypto');
const readline = require('readline')
const reader = require("readline-sync");


const num_machines = reader.question("How many machines will you use to deploy subnet?\n");
const num_subnet = reader.question("How many subnet nodes will you deploy in total?\n");
const ip_1 = reader.question("What is the ip address of machine1?\n");

if (num_machines==0 || num_subnet ==0){
  console.log('Number of machines or subnet nodes cannot be 0')
  exit()
}

if (!(num_machines%1===0 && num_subnet%1===0)) {
  console.log('Number of machines or subnet nodes must be an integer')
  exit()
}
if (!require('net').isIP(ip_1)){
  console.log('Invalid IP address')
  exit()
}

// console.log(num_machines)
// console.log(num_subnet)
// console.log(ip_1)



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

bootnode = genBootNode(machine_id=1)
doc['services']['bootnode'] = bootnode

subnet_services = genServices(machine_id=1)
Object.entries(subnet_services).forEach(entry => {
  const [key, value] = entry;
  doc['services'][key]=value
});

text = yaml.dump(doc, {
})
try{
  fs.unlinkSync('./compose-output.yml')
} catch {}

fs.writeFile('./compose-output.yml', text, err => {
  if (err) {
    console.error(err);
  }
});

fs.rmSync('./config', { recursive: true, force: true });
fs.mkdirSync('./config')

//gen base configs
commonconf = genServicesConfig(ip_1)
fs.writeFileSync('./config/common.env', commonconf, err => {
  if (err) {
    console.error(err);
  }
});

try{
  keysJson = fs.readFileSync('./keys.json')   //reuse keys if exist and enough for subnet nodes 
  keys = JSON.parse(keysJson)
  if (Object.keys(keys).length < num_subnet){
    keys = genSubnetKeys(num_subnet)
  }
}catch(err){
  keys = genSubnetKeys(num_subnet)
}
try{
  fs.unlinkSync('./keys.json')
}catch{}
jsonData = JSON.stringify(keys, null, 2);
fs.writeFile('./keys.json', jsonData, (err) => {
    if (err) {
      console.error('Error writing file:', err);
    }
});

for (let i=1; i<=num_subnet; i++){
  subnetconf = genSubnetConfig(i, keys, ip_1)
  fs.writeFileSync(`./config/subnet${i}.env`, subnetconf, err => {
  if (err) {
    console.error(err);
  }
  })
}

//checkpoint contract deployment
deployment_json = genDeploymentJson(keys)
jsonData = JSON.stringify(deployment_json, null, 2);
fs.writeFile('./config/deployment.json', jsonData, (err) => {
  if (err) {
    console.error('Error writing file:', err);
  }
})

//deployment commands list 
commands = genCommands(num_machines)
try{
  fs.unlinkSync('./commands.txt')
}catch {

}
fs.writeFile('./commands.txt', commands, err => {
  if (err) {
    console.error(err);
  }
});


function genSubnetNodes(machine_id, num, start_num=1) {
  subnet_nodes = {}
  for (let i=start_num; i < start_num+num; i++) {
    node_name='subnet'+i.toString()
    volume='./xdcchain'+i.toString()+':/work/xdcchain'
    config='${SUBNET_CONFIG_PATH}/subnet'+i.toString()+'.env'
    compose_profile='machine'+machine_id.toString()
    subnet_nodes[node_name] = {
      'image': 'localbuild-subnet:latest',
      'volumes': [volume, '${SUBNET_CONFIG_PATH}/genesis.json:/work/genesis.json'],
      'restart': 'always',
      'network_mode': 'host',
      'env_file': ['${SUBNET_CONFIG_PATH}/common.env', config],
      'profiles': [compose_profile]
    }

  }
  return subnet_nodes
}

function genBootNode(machine_id){
  config='${SUBNET_CONFIG_PATH}/common.env'
  machine='machine'+machine_id.toString()
  bootnode = {
    'image': 'xinfinorg/xdcsubnets:latest',
    'restart': 'always',
    'env_file': config,
    'volumes': ['./bootnodes:/work/bootnodes'],
    'entrypoint': ['bash','/work/start-bootnode.sh'],
    'command': ['-verbosity', '6', '-nodekey', 'bootnode.key', '--addr', ':30301'],
    'ports': ['30301:30301/tcp','30301:30301/udp'],
    'profiles': [machine]
  }
  return bootnode
}

function genServices(machine_id) {
  config='${SUBNET_CONFIG_PATH}/common.env'
  // machine='services_machine'+machine_id.toString()
  machine='services'
  relayer = {
    'image': 'xinfinorg/xdc-relayer:latest',
    'restart': 'always',
    'env_file': config,
    'profiles': [machine]
  }
  stats = {
    'image': 'xinfinorg/subnet-stats-service:latest',
    'restart': 'always',
    'env_file': config,
    'volumes': ['./stats-service/logs:/app/logs'],
    'ports': '3000:3000',
    'profiles': [machine]
  }
  mainnet = {    
    'image': 'xinfinorg/devnet:latest',
    'restart': 'always',
    'env_file': config,
    'ports': ['40313:30303', '9555:8545', '9565:8555'],
    'profiles': [machine]
  }
  puppeth = {
    'image': 'xinfinorg/xdcsubnets:latest',
    'entrypoint': ['puppeth'],
    'volumes': ['./puppeth:/root/.puppeth'],
  }

  services = {
    'relayer': relayer,
    'stats': stats,
    'mainnet': mainnet,
    'bootnode': bootnode,
    'puppeth': puppeth
  }
  return services
}

function genSubnetConfig(subnet_id, key, ip_1){
  key_name = `key${subnet_id}`
  private_key = key[key_name]['PrivateKey']
  port = 30303+subnet_id-1
  rpcport = 8545+subnet_id-1
  wsport= 8555+subnet_id-1
  config = `
INSTANCE_NAME=subnet${subnet_id}
PRIVATE_KEY=${private_key}
BOOTNODES=enode://aaaa@${ip_1}:30301
NETWORK_ID=102
SYNC_MODE=full
RPC_API=admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS
STATS_SERVICE_ADDRESS=${ip_1}:3000
STATS_SECRET=xxxxxxxxxxxx
PORT=${port}
RPCPORT=${rpcport}
WSPORT=${wsport}
LOG_LEVEL=2
`

return config
}

function genServicesConfig(ip_1){
  config=`
# Bootnode
EXTIP=${ip_1}

# Stats and relayer
PARENTCHAIN_URL=https://aaaa.com/mainnet
PARENTCHAIN_WALLET=0x0000000000000000000000000000000000000000
PARENTCHAIN_WALLET_PK=0x0000000000000000000000000000000000000000000000000000000000000000
SUBNET_URL=https://aaaa.com/subnet
CHECKPOINT_CONTRACT=0x0000000000000000000000000000000000000000
SLACK_WEBHOOK=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX

# Parent Chain Observe Node
PARENTCHAIN_NODE_NAME=mainnet_observer

# Share Variable
STATS_SECRET=xxxxxxxxxxxx
`
  return config
}

function genSubnetKeys(num){
  const keys = {}
  for ( let i = 1; i <= num; i++) {
      const key = `key${i}`
      const privateKey = crypto.randomBytes(32).toString('hex');
      const wallet = new ethers.Wallet(privateKey);
      keys[key] = {
          "PrivateKey": privateKey,
          "0x":wallet.address,
          "xdc": wallet.address.replace(/^0x/i, "xdc"),
      }
  }
  return keys

}

function genDeploymentJson(keys){
  num = Object.keys(keys).length;
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
    "xdcdevnet": "https://devnetstats.apothem.network/devnet",
    "xdcmainnet": "127.0.0.1:40313", 
    "xdcsubnet": "127.0.0.1:30303"
  }
  return deployment

}

function genCommands(num_machines){
  conf_path = __dirname+'/config/'
  // set_path='export SUBNET_CONFIG_PATH='+conf_path
  set_env='SUBNET_CONFIG_PATH='+conf_path
  commands=''
  for(let i=1; i <= num_machines; i++){
    machine_name = 'machine'+i.toString()
    commands+=machine_name+':\n'
    commands+=`  docker-compose up -d --profile ${machine_name} -e ${set_env} \n`
  }

  commands+=`\n\nmachine1:\n`
  commands+=`  docker-compose up -d --profile services -e ${set_env} \n`
  return commands


}