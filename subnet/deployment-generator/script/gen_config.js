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
    subnet:   (process.env.VERSION_SUBNET   || 'v0.1.6'),
    bootnode: (process.env.VERSION_BOOTNODE || 'v0.1.6'),
    observer: (process.env.VERSION_OBSERVER || 'latest'),
    relayer:  (process.env.VERSION_RELAYER  || 'v0.1.4'),
    stats:    (process.env.VERSION_STATS    || 'v0.1.6'),
    frontend: (process.env.VERSION_FRONTEND || 'v0.1.6')
  },
  parentchain:{
    network:    (process.env.PARENTCHAIN              || 'devnet'),
    // url:        '',
    pubkey:     ''                                                ,
    privatekey: (process.env.PARENTCHAIN_WALLET_PK    || '')      ,
  },
  keys: {
    subnets_addr: []                                        ,
    subnets_pk: (process.env.SUBNETS_PK               || ''),
    grandmaster_addr: ''                                    ,
    grandmaster_pk: (process.env.GRANDMASTER_PK       || ''),
  }
};


if (!config.num_machines || !config.num_subnet || !config.network_name){
  console.log('NUM_MACHINE and NUM_SUBNET and NETWORK_NAME must be set')
  process.exit()
}

if (config.num_machines==0 || config.num_subnet ==0){
  console.log('NUM_MACHINE and NUM_SUBNET cannot be 0')
  process.exit()
}

if (!net.isIP(config.ip_1)){
  console.log('MAIN_IP Invalid IP address')
  process.exit()
}

if (!config.network_name || config.network_name==''){
  console.log('NETWORK_NAME cannot be empty')
  process.exit()
}

if (config.network_id<1 || config.network_id >= 65536) {
  console.log('NETWORK_ID should be in range of 1 to 65536')
  process.exit()
}

if (config.secret_string=='') {
  console.log('SERVICES_SECRET cannot be empty string')
  process.exit()
}

if (!(config.relayer_mode == 'full' || config.relayer_mode == 'lite')) {
  console.log('RELAYER_MODE only accepts \'full\' or \'lite\' (default full)')
  process.exit()
}

if (!(config.parentchain.network == 'devnet'  || 
      config.parentchain.network == 'testnet' || 
      config.parentchain.network == 'mainnet' )){
  console.log('PARENTCHAIN must be devnet, testnet, or mainnet ')
  process.exit()
}

if (config.parentchain.privatekey != ''){
  try{
    config.parentchain.pubkey = validatePK(config.parentchain.privatekey)
  }catch{
    console.log('Invalid PARENTCHAIN_WALLET_PK')
    process.exit()
  }
}

if (config.keys.grandmaster_pk != ''){
  try{
    config.keys.grandmaster_addr = validatePK(config.keys.grandmaster_pk)
  }catch{
    console.log('Invalid GRANDMASTER_PK')
    process.exit()
  }
} else {
    const privatekey = crypto.randomBytes(32).toString('hex');
    const wallet = new ethers.Wallet(privatekey)
    config.keys.grandmaster_pk = privatekey
    config.keys.grandmaster_addr = wallet.address

}

if (config.keys.subnets_pk != ''){
  try{
    let output_pk = []
    let output_wallet = []
    let pks = config.keys.subnets_pk.split(',')
    pks.forEach(pk => {
      const wallet = new ethers.Wallet(pk) //validate pk with crypto
      output_pk.push(wallet.privateKey)
      output_wallet.push(wallet.address)
    })
    config.keys.subnets_pk=output_pk
    config.keys.subnets_addr=output_wallet

  }catch{
    console.log('Invalid SUBNETS_PK please make sure keys are correct length, comma separated with no whitespace or invalid characters')
    process.exit()
  }

  if (config.keys.subnets_addr.length != config.num_subnet) {
    console.log(`number of keys in SUBNETS_PK (${config.keys.subnets_addr.length}) does not match NUM_SUBNET (${config.num_subnet})`)
    process.exit()
  }

  const setPK = new Set(config.keys.subnets_pk) 
  if (setPK.size != config.keys.subnets_pk.length){
    console.log('found duplicate keys in SUBNETS_PK')
    process.exit()
  }

} else {
  let output_pk = []
  let output_wallet = []
  for (let i=0; i<config.num_subnet; i++){
    const privatekey = crypto.randomBytes(32).toString('hex');
    const wallet = new ethers.Wallet(privatekey)
    output_pk.push(wallet.privateKey) 
    output_wallet.push(wallet.address)
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

module.exports = config

function validatePK(private_key){
  let wallet = new ethers.Wallet(private_key)
  return wallet.address
}
