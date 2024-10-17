# Script to Turn Nodes into Masternodes

## Usage and Result
```
python add_masternode.py -n some_value
# -n refers to the number of masternode to add into the chain. The maximum value is 3122. 
```

After running the script, 
- A list of masternodes' private key are generated into **MASTERNODE_KEY_FOLDER**. 
- A transaction record will be created to help checking. Each line in the file can be used to be track the transaction status(like which block it is added into).

## Configuration Parameters in config.py
- **NODE_RPC**: RPC endpoint the web3 should connect to. It should be the rpc link used by the default nodes
- **CONTRACT_JSON**: path to the XDCValidator contract abi. Default is sufficient
- **RICH_KEY**: path to the rich account private key who owns a lot of XDC tokens. This file should not be modified
- **OWNER_KEY**: path to the owner account private key. All the masternodes generated belong to this owner
- **GENESIS**: path to genesis file
- **MASTERNODE_KEY_FOLDER**: path to directory where masternode private keys are created into
- **TRANSACTION_RECORD**: path to the transaction record

## Correct Workflow
1. Start initial nodes. 
2. Update config.py and run add_masternode.py
3. Start other nodes where their wallet will import private keys from **MASTERNODE_KEY_FOLDER**
4. Wait for the next epoch to be added into masternodes