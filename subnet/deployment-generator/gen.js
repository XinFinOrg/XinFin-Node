const { profile } = require('console');
const fs = require('fs');
const yaml = require('js-yaml');
const { exit } = require('process');
const crypto = require('crypto');
const readline = require('readline')
const reader = require("readline-sync");
const ethers = require('ethers');

const num_machines = parseInt(reader.question("How many machines will you use to deploy subnet?\n"));
const num_subnet = parseInt(reader.question("How many subnet nodes will you deploy in total?\n"));
const ip_1 = reader.question("What is the ip address of machine1?\n");
const network_name = reader.question("What is the network name?\n");
var network_id = reader.question("What is the network id? (default random)\n"); 
const secret_string = crypto.randomBytes(10).toString('hex');



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

if (network_name==''){
  console.log('network name cannot be empty')
  exit()
}

if (network_id==''){
  network_id=Math.floor(Math.random() * (65536 - 1) + 1)
}else if (network_id<1 || network_id >= 65536) {
  console.log('network ID should be in range of 1 to 65536')
  exit()
}

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

subnet_services = genServices(machine_id=1)
Object.entries(subnet_services).forEach(entry => {
  const [key, value] = entry;
  doc['services'][key]=value
});

text = yaml.dump(doc, {
})
try{
  fs.unlinkSync('./docker-compose.yml')
} catch {}

fs.writeFile('./docker-compose.yml', text, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

fs.rmSync('./config', { recursive: true, force: true });
fs.mkdirSync('./config')

//gen base configs
commonconf = genServicesConfig(ip_1, secret=secret_string)
fs.writeFileSync('./config/common.env', commonconf, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

// try{
//   keysJson = fs.readFileSync('./keys.json')   //reuse keys if exist and enough for subnet nodes 
//   keys = JSON.parse(keysJson)
//   if (Object.keys(keys).length-1 < num_subnet){
//     keys = genSubnetKeys(num_subnet)
//   }
// }catch(err){
//   keys = genSubnetKeys(num_subnet)
// }

keys = genSubnetKeys(num_subnet)                //always gen new keys
jsonData = JSON.stringify(keys, null, 2);
fs.writeFile('./config/keys.json', jsonData, (err) => {
    if (err) {
      console.error('Error writing file:', err);
      exit()
    }
});

for (let i=1; i<=num_subnet; i++){
  subnetconf = genSubnetConfig(i, keys, ip_1, network_id=network_id, secret=secret)
  fs.writeFileSync(`./config/subnet${i}.env`, subnetconf, err => {
  if (err) {
    console.error(err);
    exit()
  }
  })
}
compose_conf = genComposeEnv()
try{
  fs.unlinkSync('./docker-compose.env')
}catch {}

fs.writeFile('./docker-compose.env', compose_conf, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

//checkpoint contract deployment
deployment_json = genDeploymentJson(keys)
jsonData = JSON.stringify(deployment_json, null, 2);
fs.writeFile('./config/deployment.json', jsonData, (err) => {
  if (err) {
    console.error('Error writing file:', err);
    exit()
  }
})

//deployment commands list 
commands = genCommands(num_machines, network_name, network_id, num_subnet, keys)
try{
  fs.unlinkSync('./commands.txt')
}catch {}



fs.writeFile('./commands.txt', commands, err => {
  if (err) {
    console.error(err);
    exit()
  }
});

console.log('gen successful, follow the instructions in command.txt')

//genesis.json step

function genSubnetNodes(machine_id, num, start_num=1) {
  subnet_nodes = {}
  for (let i=start_num; i < start_num+num; i++) {
    node_name='subnet'+i.toString()
    volume='./xdcchain'+i.toString()+':/work/xdcchain'
    config='${SUBNET_CONFIG_PATH}/subnet'+i.toString()+'.env'
    compose_profile='machine'+machine_id.toString()
    subnet_nodes[node_name] = {
      'image': 'xinfinorg/xdcsubnets:latest',
      'volumes': [volume, '${SUBNET_CONFIG_PATH}/genesis.json:/work/genesis.json'],
      'restart': 'always',
      'network_mode': 'host',
      // 'env_file': ['${SUBNET_CONFIG_PATH}/common.env', config],
      'env_file': [config],
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
    'command': ['-verbosity', '6', '-nodekey', 'bootnode.key'],
    'ports': ['20301:20301/tcp','20301:20301/udp'],
    'profiles': [machine]
  }
  return bootnode
}

function genMainnet(machine_id){
  config='${SUBNET_CONFIG_PATH}/common.env'
  machine='machine'+machine_id.toString()
  mainnet = {    
    'image': 'xinfinorg/devnet:latest',
    'restart': 'always',
    'env_file': config,
    'ports': ['40313:30303', '9555:8545', '9565:8555'],
    'profiles': [machine]
  }
  return mainnet
}

function genServices(machine_id) {
  config='${SUBNET_CONFIG_PATH}/common.env'
  // machine='services_machine'+machine_id.toString()
  machine='services'
  frontend = {
    'image': 'xinfinorg/subnet-frontend:latest',    
    'restart': 'always',
    'volumes': [`${config}:/app/.env.local`],
    'ports': ['5000:5000'],
    'profiles': [machine]
  }
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
    'ports': ['3000:3000'],
    'profiles': [machine]
  },
  puppeth = {
    'image': 'xinfinorg/xdcsubnets:latest',
    'entrypoint': ['puppeth'],
    'volumes': ['./puppeth:/root/.puppeth'],
    'profiles': ['none']
  }, 
  bootnode=genBootNode(machine_id),
  mainnet=genMainnet(machine_id),


  services = {
    'bootnode': bootnode,
    'mainnet': mainnet,
    'relayer': relayer,
    'stats': stats,
    'puppeth': puppeth,
    'frontend': frontend,
  }

  return services
}

function genSubnetConfig(subnet_id, key, ip_1, network_id, secret){
  key_name = `key${subnet_id}`
  private_key = key[key_name]['PrivateKey']
  port = 20303+subnet_id-1
  rpcport = 8545+subnet_id-1
  wsport= 8555+subnet_id-1
  config = `
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

return config
}

function genServicesConfig(ip_1, secret){
  config=`
# Bootnode
EXTIP=${ip_1}
BOOTNODE_PORT=20301

# Stats and relayer
#PARENTCHAIN_URL=http://${ip_1}:9555
PARENTCHAIN_URL=https://devnetstats.apothem.network/devnet
PARENTCHAIN_WALLET=0x0000000000000000000000000000000000000000
PARENTCHAIN_WALLET_PK=0x0000000000000000000000000000000000000000000000000000000000000000
SUBNET_URL=http://${ip_1}:8545
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
  return config
}

function genSubnetKeys(num){
  const keys = {}
  for ( let i = 1; i <= num+1; i++) {
      const key = `key${i}`
      const privateKey = crypto.randomBytes(32).toString('hex');
      const wallet = new ethers.Wallet(privateKey);
      if (i==num+1){
        keys['Grandmaster'] = {
          "PrivateKey": privateKey,
          "0x":wallet.address,
          "xdc": wallet.address.replace(/^0x/i, "xdc"),
          "short": wallet.address.replace(/^0x/i, '')
        }

      }else{
        keys[key] = {
            "PrivateKey": privateKey,
            "0x":wallet.address,
            "xdc": wallet.address.replace(/^0x/i, "xdc"),
            "short": wallet.address.replace(/^0x/i, '')
      }
    }
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
    // "xdcparentnet": "http://127.0.0.1:40313", 
    "xdcsubnet": "http://127.0.0.1:8545"
  }
  return deployment

}

function genCommands(num_machines, network_name, network_id, num_subnet, keys){
  conf_path = __dirname+'/config/'
  set_env='SUBNET_CONFIG_PATH='+conf_path
  var commands=''
  commands+=`\nmachine1:                install requirements\n`
  commands+=`  ./setup.sh\n`

  commands+=`\nmachine1:                create genesis.json with wizard\n`
  commands+=`  docker compose --env-file docker-compose.env run puppeth\n`

  indent='    '
  out = genGenesisInstructions(
    network_name=network_name, 
    network_id=network_id, 
    num_subnet=num_subnet, 
    keys=keys,
    indent=indent
    )
  join_str='\n'+indent
  out = out.join(join_str)
  commands+='    '+out+'\n'

  commands+=`\nmachine1:                move genesis file\n`
  commands+=`  cp puppeth/${network_name} config/genesis.json\n\n`

  for(let i=1; i <= num_machines; i++){
    machine_name = 'machine'+i.toString()
    commands+=machine_name+`:                deploy subnet on machine${i}\n`
    // commands+=`  docker-compose up -d --profile ${machine_name} -e ${set_env} \n`
    if (i!=1){
      commands+=`  copy docker-compose.yml,docker-compose.env,config/subnetX.env to ${machine_name}. Make sure docker-compose.env points to subnetX.env directory. Take note of the "subnet" contract value\n`
    }
    commands+=`  docker compose --env-file docker-compose.env --profile ${machine_name} pull\n`
    commands+=`  docker compose --env-file docker-compose.env --profile ${machine_name} up -d\n\n` //composeV2
  }

  commands+=`\nmachine1:                deploy checkpoint smart contract\n`
  commands+=`  ./deploy_csc.sh  <PARENTCHAIN_WALLET_PK> (without '0x'). Might require multiple tries due to network issue.\n`

  commands+=`\nmachine1:                deploy checkpoint smart contract\n`
  commands+=`  make an edit to ./config/common.env to include values for PARENTCHAIN_WALLET,PARENTCHAIN_WALLET_PK,CHECKPOINT_CONTRACT (with '0x') \n`

  commands+=`\nmachine1:                start services and frontend\n`
  commands+=`  docker compose --env-file docker-compose.env --profile services pull\n`
  commands+=`  docker compose --env-file docker-compose.env --profile services up -d\n`
  return commands
}

function genComposeEnv(){
  conf_path = `SUBNET_CONFIG_PATH=${__dirname}/config/`
  return conf_path
}

function genGenesisInstructions(network_name, network_id, num_subnet, keys, indent){
  random_key = genSubnetKeys(1)['key1']['short']
  questions = []
  commands = []
  questions.push('')
  commands.push(`${network_name}`)     //name
  questions.push('')
  commands.push(`2`) //
  questions.push('')
  commands.push(`3`)  //
  questions.push('')
  commands.push('default') //blocks second
  questions.push('')
  commands.push('default')  //ethers reward
  questions.push('')
  commands.push('default')  //v2blocknum
  questions.push('')
  commands.push('default')  //v2timeout
  questions.push('')
  commands.push('default')  //v2timeout
  questions.push('')
  commands.push(Math.ceil(((2/3)*num_subnet)).toString()) //num votes to generate QC
  questions.push('')
  commands.push(keys['Grandmaster']['short']) //who owns first masternode
  questions.push('')
  commands.push(keys['Grandmaster']['short']) //grandmaster nodes 
  
  num = Object.keys(keys).length-1;
  key_string = []
  for (let i=1; i<= num; i++){
    key_name = `key${i}`
    public_key = keys[key_name]['short']
    key_string.push(public_key)
  }
  join_str='\n'+indent
  key_string = key_string.join(join_str)
  questions.push('')
  commands.push(key_string) //master nodes 
  questions.push('')
  commands.push('default') //blocks per epoch
  questions.push('')
  commands.push('default') //gap block
  questions.push('')
  commands.push(keys['Grandmaster']['short']) //foundation wallet address
  questions.push('')
  commands.push('1111111111111111111111111111111111111111')//Which accounts are allowed to confirm in Foudation MultiSignWallet?
  questions.push('')
  commands.push('default')  //How many require for confirm tx in Foudation MultiSignWallet? 
  questions.push('')
  commands.push('1111111111111111111111111111111111111111') //Which accounts are allowed to confirm in Team MultiSignWallet?
  questions.push('')
  commands.push('default')  //How many require for confirm tx in Team MultiSignWallet?
  questions.push('')
  commands.push('1111111111111111111111111111111111111111') //What is swap wallet address for fund 55m XDC?
  questions.push('')
  commands.push(keys['Grandmaster']['short']) //Which accounts should be pre-funded? 
  questions.push('')
  commands.push(`${network_id}`) //final input network_id
  
  return commands
}