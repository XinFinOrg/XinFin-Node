
const config = require('./config_gen')
Object.freeze(config)

module.exports = { 
  genSubnetKeys,
  genDeploymentJson,
  genDeploymentJsonMac,
  genCommands,
  genGenesisInputFile,
};


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
      "short": address.replace(/^0x/i, '')
    }
  }
  keys['Grandmaster'] = {
    "PrivateKey": config.keys.grandmaster_pk,
    "0x": config.keys.grandmaster_addr,
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
    "xdcsubnet": `http://${config.ip_1}:8545`
  }
  return deployment

}

function genDeploymentJsonMac(keys){
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
    "xdcsubnet": `http://127.0.0.1:8545`
  }
  return deployment

}

function genCommands(){
  conf_path = __dirname+'/config/'
  set_env='SUBNET_CONFIG_PATH='+conf_path
  var commands=''

  for(let i=1; i <= config.num_machines; i++){
    machine_name = 'machine'+i.toString()
    commands+=machine_name+`:                deploy subnet on machine${i}\n`
    // commands+=`  docker-compose up -d --profile ${machine_name} -e ${set_env} \n`
    if (i!=1){
      commands+=`  Prerequisite: copy docker-compose.yml,docker-compose.env,config/subnetX.env to ${machine_name}. Make sure docker-compose.env points to subnetX.env directory.\n`
    }
    commands+=`  docker compose --env-file docker-compose.env --profile ${machine_name} pull\n`
    commands+=`  docker compose --env-file docker-compose.env --profile ${machine_name} up -d\n\n` //composeV2
  }
                                    
  commands+=`\nmachine1:                deploy checkpoint smart contract\n` // 
  commands+=`  cd ..\n`
  commands+=`  docker run --env-file generated/common.env   \\
    -v $(pwd)/generated/:/app/generated/       \\
    --network host                             \\
    --entrypoint 'bash' xinfinorg/subnet-generator:v0.1.6 ./deploy_csc.sh \n`       
  // commands+=`  make an edit to ./config/common.env to include values for CHECKPOINT_CONTRACT \n`
  commands+=`  cd generated\n`
  commands+=`\nmachine1:                start services and frontend\n`
  commands+=`  docker compose --env-file docker-compose.env --profile services pull\n`
  commands+=`  docker compose --env-file docker-compose.env --profile services up -d\n`
  return commands
}

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
    if (k === 'Grandmaster'){
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

