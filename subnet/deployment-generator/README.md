# Overview
  The Subnet deployment generator is a wizard for easy subnet deployment. It generates all the necessary files and configs you'll need. There are 5 questions you have to answer. 

    How many machines will you use to deploy subnet?
    How many subnet nodes will you deploy in total?
    What is the ip address of machine1?
    What is the network name?
    What is the network id? (default random)
  In the setup scheme machine1 will host all the subnet services(relayer, stats, frontend) while the subnet miner nodes will be spread out among all machines.
  
  The IP address of machine1 is needed, this is the IP that is known to all other machines, could be private or public (preferrably private)

  The deployment is docker based, the main deployment file is `docker-compose.yml`. The `docker-compose.env` is the injection point to all configs. Then, ENVs for the services is included in `config` directory. Other files include `genesis.json` file to initialize subnet chain, `deployment.json` to deploy the checkpoint smartcontract, and `keys.json` the keypairs for subnet nodes + grandmaster node.



# Requirements
  node v20 (18 could work)

  docker, docker compose V2

  `./setup.sh` is the script for setting up requirements on a fresh machine.


# Steps
  1. install dependencies
      ```
      npm install
      ```

      ``` 
      npm install -g yarn
      ```
  2. run config generation script
      ```
      node gen.js    
      ```

  3. follow the generated instructions in `commands.txt`


## Debug guide (how to know if my subnet is running?)
  ### Subnet nodes
  1. Check logs
  ```
  docker logs -f <container_name> 
  ```
  Assuming log level 4, you want to look for logs with blockNum, and blockNum should increase with time.

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