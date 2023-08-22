# Overview
  The Subnet deployment generator is config generator for all components of subnet deployment. It generates all the necessary files and configs you'll need from a simple initial docker.env file. The required parameters are 

    1. How many machines will you use to deploy subnet?
    2. How many subnet nodes will you deploy in total?
    3. IP address of the main machine
    4. Parentchain wallet with funds

  In this setup the main machine (machine1) will host all the subnet services(relayer, stats, frontend) while the subnet miner nodes will be spread out among all machines.
  
  The IP address of the main machine is needed for subnet connectivity, this is the IP that is known to all other machines, could be private or public (preferrably private)

  Once generated, the commands to startup the subnet is also provided as a generated `commands.txt` file.

  The deployment is docker based, the main deployment file is `docker-compose.yml`. The `docker-compose.env` is the injection point to all configs. Then, ENVs for the services are in `*.env` files. Other files include `genesis.json` file to initialize subnet chain, `deployment.json` to deploy the checkpoint smartcontract, and `keys.json` the keypairs for subnet nodes + grandmaster node.



# Requirements
  docker, docker compose V2

  for manual installation of docker compose V2 please refer to: https://docs.docker.com/compose/install/linux/
  
# Steps
  1. Create a `docker.env` file with parameters similar to `docker.env.example`
  
  2. Generate configurations, this will create a new `generated` directory
  ```
  docker run --env-file docker.env -v $(pwd)/generated:/app/generated xinfinorg/subnet-generator:latest && cd generated
  ```


  2. follow the generated instructions in `commands.txt` to start Subnet Nodes and make sure they are mining.

  3. follow the generated instructions in `commands.txt` to deploy the Checkpoint Smart Contract. 
  ```
  docker run                                                           \
    --env-file docker.env                                              \
    -v $(pwd)/generated/deployment.json:/app/generated/deployment.json \
    --entrypoint 'bash' xinfinorg/subnet-generator:latest ./deploy_csc.sh
  ```

  4. follow the generated instructions in `commands.txt` to deploy the Subnet Services (relayer, stats-server, frontend)

  5. Check out the Subnet UI at `<MAIN_IP>:5000`


## Debug guide (how to know if my subnet is running?)
  ### Subnet nodes
  1. Check logs
  ```
  docker logs -f <container_name> 
  ```
  Assuming log level 4 (default 2), you want to look for logs with blockNum, and blockNum should increase with time.

  2. Check chainstate

  Exec into the subnet container
  
    docker exec -it <container_name> bash


  Attach to the API process

    XDC attach /work/xdcchain/XDC.ipc

  Call current block api
    
    XDPoS.getV2Block()

  Check current peers

    admin.peers

  ### Subnet Services
  1. Bootnode

  Check logs, you should see messages from all subnet nodes

  2. Relayer 

  Check logs, you should see blocks being periodically submitted

  3. Stats-server

  Check logs, in `<deployment folder>/stats-service/logs/debug`, you should see block data and history data being received.
  
  4. Frontend

  Check logs or through developer console in web browser.