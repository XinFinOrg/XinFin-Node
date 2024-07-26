const net = require("net");
const config = require("./config_gen");
Object.freeze(config);

module.exports = {
  genSubnetNodes,
  genBootNode,
  genObserver,
  genServices,
  genComposeEnv,
  injectMacConfig,
};

function genSubnetNodes(machine_id, num, start_num = 1) {
  let subnet_nodes = {};
  for (let i = start_num; i < start_num + num; i++) {
    const node_name = "subnet" + i.toString();
    const volume = "./xdcchain" + i.toString() + ":/work/xdcchain";
    const config_path = "${SUBNET_CONFIG_PATH}/subnet" + i.toString() + ".env";
    const compose_profile = "machine" + machine_id.toString();
    const port = 20302 + i;
    const rpcport = 8544 + i;
    const wsport = 9554 + i;
    subnet_nodes[node_name] = {
      image: `xinfinorg/xdcsubnets:${config.version.subnet}`,
      volumes: [
        volume,
        "${SUBNET_CONFIG_PATH}/genesis.json:/work/genesis.json",
      ],
      restart: "always",
      network_mode: "host",
      env_file: [config_path],
      profiles: [compose_profile],
      ports: [
        `${port}:${port}`,
        `${rpcport}:${rpcport}`,
        `${wsport}:${wsport}`,
      ],
    };
  }
  return subnet_nodes;
}

function genBootNode(machine_id) {
  let config_path = "${SUBNET_CONFIG_PATH}/common.env";
  const machine = "machine" + machine_id.toString();
  const bootnode = {
    image: `xinfinorg/xdcsubnets:${config.version.bootnode}`,
    restart: "always",
    env_file: config_path,
    volumes: ["./bootnodes:/work/bootnodes"],
    entrypoint: ["bash", "/work/start-bootnode.sh"],
    command: ["-verbosity", "6", "-nodekey", "bootnode.key"],
    ports: ["20301:20301/tcp", "20301:20301/udp"],
    profiles: [machine],
  };
  return bootnode;
}

function genObserver(machine_id) {
  const config_path = "${SUBNET_CONFIG_PATH}/common.env";
  const machine = "machine" + machine_id.toString();
  const observer = {
    image: `xinfinorg/devnet:${config.version.observer}`,
    restart: "always",
    env_file: config_path,
    ports: ["20302:30303", "7545:8545", "7555:8555"],
    profiles: [machine],
  };
  return observer;
}

function genServices(machine_id) {
  const config_path = "${SUBNET_CONFIG_PATH}/common.env";
  const machine = "services";
  const frontend = {
    image: `xinfinorg/subnet-frontend:${config.version.frontend}`,
    restart: "always",
    env_file: config_path, // not used directly (injected via volume) but required to trigger restart if common.env changes
    volumes: [`${config_path}:/app/.env.local`],
    ports: ['5555:5555'],
    profiles: [machine]
  }
  const relayer = {
    image: `xinfinorg/xdc-relayer:${config.version.relayer}`,
    restart: "always",
    env_file: config_path,
    ports: ["4000:4000"],
    profiles: [machine],
  };
  const stats = {
    image: `xinfinorg/subnet-stats-service:${config.version.stats}`,
    restart: "always",
    env_file: config_path,
    volumes: ["./stats-service/logs:/app/logs"],
    ports: ["3000:3000"],
    profiles: [machine],
  };
  const bootnode = genBootNode(machine_id);
  // observer=genObserver(machine_id),

  const services = {
    bootnode,
    // observer,
    relayer,
    stats,
    frontend,
  };

  return services;
}

function genComposeEnv() {
  conf_path = `SUBNET_CONFIG_PATH=${config.deployment_path}/generated/`;
  return conf_path;
}

function injectMacConfig(compose_object) {
  // networks:
  //   docker_net:
  //     driver: bridge
  //     ipam:
  //       config:
  //         - subnet: 192.168.25.0/24
  const network = {
    docker_net: {
      driver: "bridge",
      ipam: {
        config: [{ subnet: "192.168.25.0/24" }],
      },
    },
  };
  // networks:
  //   docker_net:
  //     ipv4_address:
  //       192.168.25.10

  let record_services_ip = {};

  const ip_string_base = "192.168.25.";
  let start_ip = 11;
  Object.entries(compose_object["services"]).forEach((entry) => {
    const [key, value] = entry;
    const component_ip = ip_string_base + parseInt(start_ip);
    start_ip += 1;
    if (!net.isIP(component_ip)) {
      console.log(
        `ERROR: found invalid IP assignment ${component_ip} in mac mode`
      );
      process.exit(1);
    }
    const component_network = {
      docker_net: {
        ipv4_address: component_ip,
      },
    };
    compose_object["services"][key]["networks"] = component_network;
    delete compose_object["services"][key]["network_mode"];
    record_services_ip[key] = component_ip;
  });

  compose_object["networks"] = network;

  return compose_object, record_services_ip;
}
