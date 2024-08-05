const fs = require("fs");
const yaml = require("js-yaml");
const { exit } = require("process");
const config = require("./config_gen");
const gen_compose = require("./gen_compose");
const gen_env = require("./gen_env");
const gen_other = require("./gen_other");

Object.freeze(config);
// console.log(config)

// const num_machines = config.num_machines
// const num_subnet = config.num_subnet
// const ip_1 = config.ip_1
// const network_name = config.network_name
// const network_id = config.network_id
// const secret_string = config.secret_string
// const output_path = `${__dirname}/../generated/`

const keys = gen_other.genSubnetKeys();

const num_per_machine = Array(config.num_machines);
// integer division
for (let i = 0; i < config.num_machines; i++) {
  num_per_machine[i] = Math.floor(config.num_subnet / config.num_machines);
}
// divide up the remainder
for (let i = 0; i < config.num_subnet % config.num_machines; i++) {
  num_per_machine[i]++;
}
num_per_machine.reverse(); // let first machines host services, put fewer subnets

// gen docker-compose
let doc = {
  version: "3.7",
  services: {},
};

let start_num = 1;
for (let i = 1; i <= config.num_machines; i++) {
  const subnet_nodes = gen_compose.genSubnetNodes(
    (machine_id = i),
    (num = num_per_machine[i - 1]),
    (start_num = start_num)
  );
  start_num += num_per_machine[i - 1];
  Object.entries(subnet_nodes).forEach((entry) => {
    const [key, value] = entry;
    doc["services"][key] = value;
  });
}

// gen subnets configs
const subnet_services = gen_compose.genServices((machine_id = 1));
Object.entries(subnet_services).forEach((entry) => {
  const [key, value] = entry;
  doc["services"][key] = value;
});
// checkpoint smartcontract deployment config
let deployment_json = gen_other.genDeploymentJson(keys);

if (config.operating_system === "mac") {
  doc, (ip_record = gen_compose.injectMacConfig(doc));
  commonconf = gen_env.genServicesConfigMac(ip_record);
  subnetconf = [];
  for (let i = 1; i <= config.num_subnet; i++) {
    subnetconf.push(gen_env.genSubnetConfigMac(i, keys, ip_record));
  }
} else if (config.operating_system === "linux") {
  commonconf = gen_env.genServicesConfig();
  subnetconf = [];
  for (let i = 1; i <= config.num_subnet; i++) {
    subnetconf.push(gen_env.genSubnetConfig(i, keys));
  }
} else {
  console.log(`ERROR: unknown OS ${config.operating_system} not supported`);
  process.exit(1);
}

const compose_content = yaml.dump(doc, {});
const compose_conf = gen_compose.genComposeEnv();

// deployment commands list
const commands = gen_other.genCommands();
const genesis_input = gen_other.genGenesisInputFile(
  config.network_name,
  config.network_id,
  config.num_subnet,
  keys
);
const genesis_input_file = yaml.dump(genesis_input, {});

writeGenerated(config.generator.output_path);
copyScripts(config.generator.output_path);

console.log("gen successful, follow the instructions in command.txt");

function writeGenerated(output_dir) {
  // writing files
  // fs.rmSync(`${output_path}`, { recursive: true, force: true }); //wont work with docker mount
  // fs.mkdirSync(`${output_path}`) //won't work with docker mount
  fs.writeFileSync(`${output_dir}/placeholder.txt`, "-", (err) => {
    if (err) {
      console.error(err);
      exit();
    }
  });

  fs.writeFileSync(
    `${output_dir}/docker-compose.yml`,
    compose_content,
    (err) => {
      if (err) {
        console.error(err);
        exit();
      }
    }
  );

  fs.writeFileSync(`${output_dir}/common.env`, commonconf, (err) => {
    if (err) {
      console.error(err);
      exit();
    }
  });

  const keys_json = JSON.stringify(keys, null, 2);
  fs.writeFile(`${output_dir}/keys.json`, keys_json, (err) => {
    if (err) {
      console.error("Error writing key file:", err);
      exit();
    }
  });

  for (let i = 1; i <= config.num_subnet; i++) {
    fs.writeFileSync(
      `${output_dir}/subnet${i}.env`,
      subnetconf[i - 1],
      (err) => {
        if (err) {
          console.error(err);
          exit();
        }
      }
    );
  }

  fs.writeFileSync(`${output_dir}/docker-compose.env`, compose_conf, (err) => {
    if (err) {
      console.error(err);
      exit();
    }
  });

  deployment_json = JSON.stringify(deployment_json, null, 2);
  fs.writeFileSync(
    `${output_dir}/deployment.config.json`,
    deployment_json,
    (err) => {
      if (err) {
        console.error("Error writing file:", err);
        exit();
      }
    }
  );

  fs.writeFileSync(
    `${output_dir}/genesis_input.yml`,
    genesis_input_file,
    (err) => {
      if (err) {
        console.error(err);
        exit();
      }
    }
  );

  fs.writeFileSync(`${output_dir}/commands.txt`, commands, (err) => {
    if (err) {
      console.error(err);
      exit();
    }
  });
}

function copyScripts(output_dir) {
  fs.writeFileSync(`${output_dir}/scripts/placeholder.txt`, "-", (err) => {
    if (err) {
      console.error(err);
      exit();
    }
  });
  fs.copyFileSync(`${__dirname}/../scripts/check_mining.sh`, `${output_dir}/scripts/check_mining.sh`);
  fs.copyFileSync(`${__dirname}/../scripts/check_peer.sh`, `${output_dir}/scripts/check_peer.sh`);
  fs.copyFileSync(`${__dirname}/../scripts/docker_up.sh`, `${output_dir}/scripts/docker_up.sh`);
  fs.copyFileSync(`${__dirname}/../scripts/docker_down.sh`, `${output_dir}/scripts/docker_down.sh`);
}
