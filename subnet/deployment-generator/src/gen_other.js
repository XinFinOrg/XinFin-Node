const config = require("./config_gen");
Object.freeze(config);

module.exports = {
  genSubnetKeys,
  genDeploymentJson,
  genCommands,
  genGenesisInputFile,
};

function genSubnetKeys() {
  const keys = {};
  // const num = config.keys.subnets_addr.length
  for (let i = 0; i < config.keys.subnets_addr.length; i++) {
    const key = `key${i + 1}`;
    const private_key = config.keys.subnets_pk[i];
    const address = config.keys.subnets_addr[i];
    keys[key] = {
      PrivateKey: private_key,
      "0x": address,
      short: address.replace(/^0x/i, ""),
    };
  }
  keys["Grandmaster"] = {
    PrivateKey: config.keys.grandmaster_pk,
    "0x": config.keys.grandmaster_addr,
    short: config.keys.grandmaster_addr.replace(/^0x/i, ""),
  };
  if (Object.keys(keys).length !== config.num_subnet + 1) {
    // sanity check
    console.log("bad case, key length not equal number of subnets");
    console.log(Object.keys(keys).length, config.num_subnet + 1);
    console.log(keys);
    process.exit();
  }

  return keys;
}

function genDeploymentJson(keys) {
  const num = Object.keys(keys).length - 1;
  const validators = [];
  for (let i = 1; i <= num; i++) {
    let key_name = `key${i}`;
    let public_key = keys[key_name]["0x"];
    validators.push(public_key);
  }

  const deployment = {
    validators,
    gap: 450,
    epoch: 900,
  };
  return deployment;
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

function genCommands() {
  const conf_path = __dirname + "/config/";
  const set_env = "SUBNET_CONFIG_PATH=" + conf_path;
  let csc_mode = "full"
  if (config.relayer_mode == "lite"){
    csc_mode = "lite" 
  }
  let commands = "";
  commands += "Start under generated/ directory\n"
  commands += "\n1. Deploy Subnet nodes\n";
  for (let i = 1; i <= config.num_machines; i++) {
    const machine_name = "machine" + i.toString();
    if (config.num_machines > 1){
    commands +=
      machine_name + `:                deploy subnet on machine${i}\n`;
    }
    if (i !== 1) {
      commands += `  Prerequisite: copy docker-compose.yml,docker-compose.env,config/subnetX.env to ${machine_name}. Make sure docker-compose.env points to subnetX.env directory.\n`;
    }
    commands += `  docker compose --env-file docker-compose.env --profile ${machine_name} pull\n`;
    commands += `  docker compose --env-file docker-compose.env --profile ${machine_name} up -d\n\n`;
  }
  commands += "\n2. After 60 seconds, confirm the Subnet is running correctly\n";
  commands += "  ./scripts/check-mining.sh\n"
  commands += "\n3. Deploy Checkpoint Smart Contract (CSC)\n"
  commands += `  docker pull xinfinorg/csc:${config.version.csc}\n`
  if (config.operating_system == 'mac'){
    commands += `  docker run --env-file contract_deploy.env --network generated_docker_net xinfinorg/csc:${config.version.csc} ${csc_mode}\n`
  } else {
    commands += `  docker run --env-file contract_deploy.env xinfinorg/csc:${config.version.csc} ${csc_mode}\n`
  }
  commands += "\n4. Start services (relayer, backend, frontend)\n"
  commands += `  docker compose --env-file docker-compose.env --profile services pull\n`;
  commands += `  docker compose --env-file docker-compose.env --profile services up -d\n`;
  commands += "\n5. Confirm Subnet services through browser UI\n"
  commands += `  Frontend: http://${config.public_ip}:6000\n`
  commands += `  Relayer: http://${config.public_ip}:4000\n`

  if (config.relayer_mode == 'lite'){

  } else if (config.relayer_mode == 'full'){
    commands += "\n  1. Deploy XDC-Zero\n"
    commands += "\n  2. Add XDC-Zero Address to common.env\n" 
    commands += "\n  3. Restart Relayer\n"
    commands += "\n  4. Confirm Relayer is running  \n"
    commands += `    Relayer: http://${config.public_ip}:4000\n`
    commands += `    Frontend: http://${config.public_ip}:6000\n`
  } else if (config.relayer_mode == 'temp'){
    commands += "\n\nOPTIONAL: Deploy XDC-Zero crosschain framework (Require RELAYER_MODE=full)\n" //there is a branch here: user can decide to deploy REVERSE or NOT ( subnet > mainnet or subnet <> mainnet)
    commands += "\n  1. Transfer funds to your SUBNET_WALLET\n"
    commands += "\n  2. Deploy Reverse Checkpoint Smart Contract (Reverse CSC)\n"
    commands += "\n  3. Deploy XDC-Zero \n"
    commands += "\n  4. Add XDC-Zero Address to common.env\n" 
    commands += "\n  5. Restart Relayer\n"
    commands += "\n  6. Confirm Relayer is running  \n"
    commands += `    Relayer: ${config.public_ip}:4000\n`
    commands += `    Frontend: ${config.public_ip}:6000\n`
  } else {
    console.log("Error: Invalid Relayer Mode")
    exit()
  }

  return commands;
}

function genGenesisInputFile(network_name, network_id, num_subnet, keys) {
  const masternodes = [];
  const grandmasters = [];
  Object.keys(keys).forEach(function (k) {
    const v = keys[k];
    if (k === "Grandmaster") {
      grandmasters.push(v["0x"]);
    } else {
      masternodes.push(v["0x"]);
    }
  });

  const config = {
    name: network_name,
    grandmasters,
    masternodes,
    chainid: network_id,
  };
  return config;
}
