sudo docker exec -it xdcnetwork-testnet-node  XDC --exec 'eth.coinbase' --exec 'miner.setEtherbase(eth.accounts[0])' attach /work/xdcchain/XDC.ipc
