const crypto = require('crypto');
const dotenv = require('dotenv');
dotenv.config({ path: `${__dirname}/gen.env` });


console.log(__dirname)
var config = {
  // interactive: (process.env.INTERACTIVE || false),
  num_machines:    parseInt(process.env.NUM_MACHINE),
  num_subnet:      parseInt(process.env.NUM_SUBNET),
  ip_1:            (process.env.MAIN_IP               || ''),
  network_name:    (process.env.NETWORK_NAME),
  network_id:      parseInt(process.env.NETWORK_ID    || Math.floor(Math.random() * (65536 - 1) + 1)),
  secret_string:   (process.env.SERVICES_SECRET       || crypto.randomBytes(10).toString('hex')),
  relayer_mode:    (process.env.RELAYER_MODE          || 'full'), //full or lite
  version: {
    subnet:   (process.env.VERSION_SUBNET   || 'latest'),
    bootnode: (process.env.VERSION_BOOTNODE || 'latest'),
    observer: (process.env.VERSION_OBSERVER || 'latest'),
    relayer:  (process.env.VERSION_RELAYER  || 'v0.1.1'),
    stats:    (process.env.VERSION_STATS    || 'v0.1.1'),
    frontend: (process.env.VERSION_FRONTEND || 'v0.1.1')
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

if (!require('net').isIP(config.ip_1)){
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

module.exports = config