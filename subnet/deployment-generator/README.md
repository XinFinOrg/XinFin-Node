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

  2. Pull latest subnet-generator image
  ```
  docker pull xinfinorg/subnet-generator:latest
  ```
  
  3. Generate configurations, this will create a new `generated` directory
  ```
  docker run --env-file docker.env -v $(pwd)/generated:/app/generated xinfinorg/subnet-generator:latest && cd generated
  ```

  4. follow the generated instructions in `commands.txt` to start Subnet Nodes and [make sure they are mining](#subnet-nodes).

  5. follow the generated instructions in `commands.txt` to deploy the Checkpoint Smart Contract. 
  ```
  docker run                                                           \
    --env-file docker.env                                              \
    -v $(pwd)/generated/deployment.json:/app/generated/deployment.json \
    --entrypoint 'bash' xinfinorg/subnet-generator:latest ./deploy_csc.sh
  ```

  6. follow the generated instructions in `commands.txt` to deploy the Subnet Services (relayer, stats-server, frontend)

  7. Check out the Subnet UI at `<MAIN_IP>:5000`

### Removing Subnet
  1.  Change the commands in `commands.txt` to `docker compose ... down`
  ```
  docker compose --env-file docker-compose.env --profile <profile_name> down 
  ```

  2. Repeat 1. for every docker `--profile` that was started. 

  3. Inside `generated` directory, remove `bootnodes`, `stats-service`, and `xdcchain*` directories

## Debug guide (how to know if my subnet is running?)
  ### Subnet nodes

  1. Check chainstate with curl, you can change `localhost:8545` to your subnet node's RPC PORT
  
      Call current block api

      ```
      curl --location 'http://localhost:8545' \
      --header 'Content-Type: application/json' \
      --data '{"jsonrpc":"2.0","method":"XDPoS_getV2BlockByNumber","params":["latest"],"id":1}'
      ```

      Check current peers
      
      ```
      curl --location 'http://localhost:8545' \
      --header 'Content-Type: application/json' \
      --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}'
      ```

  2. Check chainstate inside docker

      Exec into the subnet container
      
      ```
      docker exec -it <container_name> bash
      ```

      Attach to the API process

      ```
      XDC attach /work/xdcchain/XDC.ipc
      ```

      Call current block api
        
      ```
      XDPoS.getV2Block()
      ```

      Check current peers

      ```
      admin.peers
      ```

3. Check logs, assuming log level 4 (default 2), you want to look for logs with blockNum, and blockNum should increase with time.
    
    ```
    docker logs -f <container_name> 
    ```



  ### Subnet Services
  1. Bootnode

  Check logs, you should see messages from all subnet nodes

  2. Relayer 

  Check logs, you should see blocks being periodically submitted

  3. Stats-server

  Check logs, in `<deployment folder>/stats-service/logs/debug`, you should see block data and history data being received.
  
  4. Frontend

  Check logs or through developer console in web browser.