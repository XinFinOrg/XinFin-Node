const crypto = require('crypto');
const net = require('net');
const dotenv = require('dotenv');
const ethers = require('ethers');
dotenv.config({ path: `${__dirname}/gen.env` });
// console.log(__dirname)

var config = {
  deployment_path:    (process.env.CONFIG_PATH            || ''),
  num_machines:       parseInt(process.env.NUM_MACHINE),
  num_subnet:         parseInt(process.env.NUM_SUBNET),
  ip_1:               (process.env.MAIN_IP                || ''),
  network_name:       (process.env.NETWORK_NAME),
  network_id:         parseInt(process.env.NETWORK_ID     || Math.floor(Math.random() * (65536 - 1) + 1)),
  secret_string:      (process.env.SERVICES_SECRET        || crypto.randomBytes(10).toString('hex')),
  relayer_mode:       (process.env.RELAYER_MODE           || 'full'), //full or lite
  docker_image_name:  (process.env.IMAGE_NAME             || 'xinfinorg/subnet-generator:latest'),
  operating_system:   (process.env.OS                     || 'linux'),
  version: {
    subnet:   (process.env.VERSION_SUBNET   || 'v0.2.1'),
    bootnode: (process.env.VERSION_BOOTNODE || 'v0.2.1'),
    observer: (process.env.VERSION_OBSERVER || 'latest'),
    relayer:  (process.env.VERSION_RELAYER  || 'v0.2.1'),
    stats:    (process.env.VERSION_STATS    || 'v0.1.8'),
    frontend: (process.env.VERSION_FRONTEND || 'v0.1.8')
  },
  parentnet:{
    network:    (process.env.PARENTNET              || 'devnet'),
    // url:        '',
    pubkey:     ''                                                ,
    privatekey: (process.env.PARENTNET_WALLET_PK    || '')      ,
  },
  keys: {
    subnets_addr: []                                        ,
    subnets_pk: (process.env.SUBNETS_PK               || ''),
    grandmaster_addr: ''                                    ,
    grandmaster_pk: (process.env.GRANDMASTER_PK       || ''),
  }
};

if (configSanityCheck(config) == true){
  module.exports = config
} else {
  console.log('bad config init file, please check again')
  process.exit()
}

function validatePK(private_key){
  let wallet = new ethers.Wallet(private_key)
  return [wallet.address, wallet.privateKey]
}

function configSanityCheck(config){
  if (!config.num_machines || !config.num_subnet || !config.network_name){
    console.log('NUM_MACHINE and NUM_SUBNET and NETWORK_NAME must be set')
    process.exit(1)
  }

  if (config.num_machines==0 || config.num_subnet ==0){
    console.log('NUM_MACHINE and NUM_SUBNET cannot be 0')
    process.exit(1)
  }

  if (!net.isIP(config.ip_1)){
    console.log('MAIN_IP Invalid IP address')
    process.exit(1)
  }

  if (!config.network_name || config.network_name==''){
    console.log('NETWORK_NAME cannot be empty')
    process.exit(1)
  }

  if (config.network_id<1 || config.network_id >= 65536) {
    console.log('NETWORK_ID should be in range of 1 to 65536')
    process.exit(1)
  }

  if (config.secret_string=='') {
    console.log('SERVICES_SECRET cannot be empty string')
    process.exit(1)
  }

  if (!(config.relayer_mode == 'full' || config.relayer_mode == 'lite')) {
    console.log('RELAYER_MODE only accepts \'full\' or \'lite\' (default full)')
    process.exit(1)
  }

  if (!(config.parentnet.network == 'devnet'  || 
        config.parentnet.network == 'testnet' || 
        config.parentnet.network == 'mainnet' )){
    console.log('PARENTNET must be devnet, testnet, or mainnet ')
    process.exit(1)
  }

  if (config.parentnet.privatekey != ''){
    try{
      config.parentnet.pubkey = validatePK(config.parentnet.privatekey)
    }catch{
      console.log('Invalid PARENTNET_WALLET_PK')
      process.exit(1)
    }
  }

  if (config.keys.grandmaster_pk != ''){
    try{
      [config.keys.grandmaster_addr, config.keys.grandmaster_pk] = validatePK(config.keys.grandmaster_pk)
    }catch{
      console.log('Invalid GRANDMASTER_PK')
      process.exit(1)
    }
  } else {
      const privatekey = crypto.randomBytes(32).toString('hex');
      [config.keys.grandmaster_addr, config.keys.grandmaster_pk] = validatePK(privatekey)
  }

  if (config.keys.subnets_pk != ''){
    try{
      let output_pk = []
      let output_wallet = []
      let pks = config.keys.subnets_pk.split(',')
      pks.forEach(pk => {
        const [address, private_key] = validatePK(pk)
        output_wallet.push(address)
        output_pk.push(private_key)
      })
      config.keys.subnets_pk=output_pk
      config.keys.subnets_addr=output_wallet

    }catch{
      console.log('Invalid SUBNETS_PK please make sure keys are correct length, comma separated with no whitespace or invalid characters')
      process.exit(1)
    }

    if (config.keys.subnets_addr.length != config.num_subnet) {
      console.log(`number of keys in SUBNETS_PK (${config.keys.subnets_addr.length}) does not match NUM_SUBNET (${config.num_subnet})`)
      process.exit(1)
    }

    const setPK = new Set(config.keys.subnets_pk) 
    if (setPK.size != config.keys.subnets_pk.length){
      console.log('found duplicate keys in SUBNETS_PK')
      process.exit(1)
    }

  } else {
    let output_pk = []
    let output_wallet = []
    for (let i=0; i<config.num_subnet; i++){
      const privatekey = crypto.randomBytes(32).toString('hex');
      const [address, private_key] = validatePK(privatekey)
      output_wallet.push(address)
      output_pk.push(private_key) 
      
    }
    config.keys.subnets_pk=output_pk
    config.keys.subnets_addr=output_wallet

  }

  if (config.operating_system == 'mac') {
    if (config.num_machines != 1){
      console.log(`OS=mac requires NUM_MACHINE=1. Due to Docker network limitation, Subnets on MacOS can only communicate within its own machine. This option is intended for single machine testing environment only`)
      process.exit()
    }
    console.log(`OS=mac specified, this option is intended for single machine testing environment only. Due to Docker network limitation, Subnets on MacOS can only communicate within its own machine.`)
  } 
  return true
}

