# Subnet Local Deployment

This README is an extension of the README in the upper /subnet directory.
The purpose of this directory is for locally hosting subnet with multiple nodes.

1. Build a local docker image with `./build_local_img.sh`. You can edit the script to build from a differrent subnet branch. 

2. In `docker-compose.yml` you can specify the image you require. For example, `localbuild-subnet:latest` - from step 1, `xinfinorg/xdcsubnets:latest` - latest master build, or another local build image.

3. The `docker-compose.yml` provided is made for an example of 3 subnet nodes which can be increased as needed.

4. Include `genesis.json` and `.env` files. Make sure the `EXTIP` bootnode config is same ip as `docker_net`.

5. `docker-compose up bootnode` start bootnode first to get bootnode URL and put in `.env` files.

6. `docker-compose up` start the rest of the services.

7. Additionally `./debug/attach` is for troubleshooting node state(of subnet node 1). The default is `XDPoS.getV2Block()`. If followed by a number like `./debug/attach 100` then it is `XDPoS.getV2Block(100)` returning contents of the 100th block. If followed by words then it will issue that command, for example `./debug/attach admin.peers` return peers of that node.