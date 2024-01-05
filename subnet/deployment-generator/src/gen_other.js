const config = require('./config_gen')
Object.freeze(config)

module.exports = {
  genSubnetKeys,
  genDeploymentJson,
  genCommands,
  genGenesisInputFile
}

function genSubnetKeys () {
  const keys = {}
  // const num = config.keys.subnets_addr.length
  for (let i = 0; i < config.keys.subnets_addr.length; i++) {
    const key = `key${i + 1}`
    const private_key = config.keys.subnets_pk[i]
    const address = config.keys.subnets_addr[i]
    keys[key] = {
      PrivateKey: private_key,
      '0x': address,
      short: address.replace(/^0x/i, '')
    }
  }
  keys['Grandmaster'] = {
    PrivateKey: config.keys.grandmaster_pk,
    "0x": config.keys.grandmaster_addr,
    short: config.keys.grandmaster_addr.replace(/^0x/i, '')
  }
  if (Object.keys(keys).length !== config.num_subnet + 1) { // sanity check
    console.log('bad case, key length not equal number of subnets')
    console.log(Object.keys(keys).length, config.num_subnet + 1)
    console.log(keys)
    process.exit()
  }

  return keys
}

function genDeploymentJson (keys) {
  const num = Object.keys(keys).length - 1
  const validators = []
  for (let i = 1; i <= num; i++) {
    let key_name = `key${i}`
    let public_key = keys[key_name]['0x']
    validators.push(public_key)
  }

  const deployment = {
    validators,
    gap: 450,
    epoch: 900
  }
  return deployment
}

// function genNetworkJson(){   //don't need this, config will overlap(duplicate) with other files, shell script in CSC docker can gen this
//   let network = {
//     "xdcsubnet": `http://${config.ip_1}:8545`,
//     "xdcparentnet": config.parentnet.url
//   }
//   return network
// }
// function genNetworkJsonMac(){
//   let network = {
//     "xdcsubnet": `http://127.0.0.1:8545`,
//     "xdcparentnet": config.parentnet.url
//   }
//   return network
// }

function genCommands () {
  const conf_path = __dirname + '/config/'
  const set_env = 'SUBNET_CONFIG_PATH=' + conf_path
  let commands = ''

  for (let i = 1; i <= config.num_machines; i++) {
    const machine_name = 'machine' + i.toString()
    commands += machine_name + `:                deploy subnet on machine${i}\n`
    // commands+=`  docker-compose up -d --profile ${machine_name} -e ${set_env} \n`
    if (i !== 1) {
      commands += `  Prerequisite: copy docker-compose.yml,docker-compose.env,config/subnetX.env to ${machine_name}. Make sure docker-compose.env points to subnetX.env directory.\n`
    }
    commands += `  docker compose --env-file docker-compose.env --profile ${machine_name} pull\n`
    commands += `  docker compose --env-file docker-compose.env --profile ${machine_name} up -d\n\n` //composeV2
  }
  commands += `\nmachine1:                deploy checkpoint smart contract\n` 
  commands += `  docker run --env-file common.env   \\
    -v $(pwd)/../generated/:/app/config       \\
    --network host                             \\
    --entrypoint './docker/deploy_proxy.sh' xinfinorg/csc:${config.version.csc}\n`
  commands += `\nmachine1:                start services and frontend\n`
  commands += `  docker compose --env-file docker-compose.env --profile services pull\n`
  commands += `  docker compose --env-file docker-compose.env --profile services up -d\n`
  return commands
}

function genGenesisInputFile (network_name, network_id, num_subnet, keys) {
// name: localNet
// certthreshold: 2
// grandmasters:
//   - "0x30f21E514A66732DA5Dff95340624fa808048601"
// masternodes:
//   - "0x25b4cbb9a7ae13feadc3e9f29909833d19d16de5"
//   - "0x3d9fd0c76bb8b3b4929ca861d167f3e05926cb68"
//   - "0x3c03a0abac1da8f2f419a59afe1c125f90b506c5"
// chainid: 29412

  const masternodes = []
  const grandmasters = []
  Object.keys(keys).forEach(function(k) {
    const v = keys[k]
    if (k === 'Grandmaster') {
      grandmasters.push(v['0x'])
    } else {
      masternodes.push(v['0x'])
    }
  })

  const config = {
    name: network_name,
    certthreshold: Math.ceil(((2 / 3) * num_subnet)),
    grandmasters,
    masternodes,
    chainid: network_id,
  }
  return config
}
