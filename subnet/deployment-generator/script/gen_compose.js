
const net = require('net');
const config = require('./config_gen')
Object.freeze(config)

module.exports = { 
  genSubnetNodes,
  genBootNode,
  genObserver,
  genServices,
  genComposeEnv,
  injectMacConfig
};


function genSubnetNodes(machine_id, num, start_num=1) {
  subnet_nodes = {}
  for (let i=start_num; i < start_num+num; i++) {
    node_name='subnet'+i.toString()
    volume='./xdcchain'+i.toString()+':/work/xdcchain'
    var config_path='${SUBNET_CONFIG_PATH}/subnet'+i.toString()+'.env'
    compose_profile='machine'+machine_id.toString()
    port = 20303+i-1
    rpcport = 8545+i-1
    wsport= 9555+i-1
    subnet_nodes[node_name] = {
      'image': `xinfinorg/xdcsubnets:${config.version.subnet}`,
      'volumes': [volume, '${SUBNET_CONFIG_PATH}/genesis.json:/work/genesis.json'],
      'restart': 'always',
      'network_mode': 'host',
      'env_file': [config_path],
      'profiles': [compose_profile],
      'ports': [`${port}:${port}`,`${rpcport}:${rpcport}`,`${wsport}:${wsport}`]
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
    'env_file': config_path,      //not used directly (injected via volume) but required to trigger restart if common.env changes
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

function genComposeEnv(){
  conf_path = `SUBNET_CONFIG_PATH=${config.deployment_path}/generated/`
  return conf_path
}

function injectMacConfig(compose_object){
  // networks:
  //   docker_net:
  //     driver: bridge
  //     ipam:
  //       config:
  //         - subnet: 192.168.25.0/24
  network = {
    "docker_net": {
      "driver": `bridge`,
      "ipam": {
        "config": [
          {"subnet": "192.168.25.0/24"}
        ]
      }
    }
  }
  // networks:
  //   docker_net:
  //     ipv4_address: 
  //       192.168.25.10

  record_services_ip={}

  ip_string_base='192.168.25.'
  start_ip=11
  Object.entries(compose_object["services"]).forEach(entry => {
    const [key, value] = entry;
    component_ip = ip_string_base+parseInt(start_ip)
    start_ip += 1
    if(!net.isIP(component_ip)){
      console.log(`ERROR: found invalid IP assignment ${component_ip} in mac mode`)
      process.exit(1)
    }
    component_network = {
      "docker_net": {
        "ipv4_address": component_ip 
      }
    }
    compose_object["services"][key]["networks"] = component_network
    delete compose_object["services"][key]["network_mode"]
    record_services_ip[key]=component_ip
  });

  compose_object["networks"]=network

  return compose_object, record_services_ip
} 
