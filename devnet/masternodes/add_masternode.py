import json
from multiprocessing.sharedctypes import Value
from time import sleep
import requests
from web3 import Web3
from eth_account import Account
from config import *
import argparse
import sys
import os


# Connect with all nodes
w3 = Web3(Web3.HTTPProvider(NODE_RPC))

# Load contract abi
with open(CONTRACT_JSON, "r") as f:
  contract = json.load(f)
# Load contract abi into web3
val_addr = "0x0000000000000000000000000000000000000088"
val_abi = contract["abi"]
val_contract = w3.eth.contract(address=val_addr, abi=val_abi)

# Load genesis file
with open(GENESIS, "r") as f:
  genesis = json.load(f)

# Load rich account
with open(RICH_KEY, "r") as f:
  privKey = f.readline().strip()
  rich_account = Account.from_key(f"0x{privKey}")

# Load generated key 1 for testing
with open(OWNER_KEY, "r") as f:
  privKey = f.readline().strip()
  owner_account = Account.from_key(f"0x{privKey}")

def parse_args():
  parser = argparse.ArgumentParser(description="Masternode key generation and election")
  parser.add_argument("-n", "--number", default=1, help="number to masternodes to add")
  return parser.parse_args()

def transfer(value, from_account, to_addr):
  signed_transaction = w3.eth.account.sign_transaction({
    "from": from_account.address,
    "to": to_addr,
    "nonce": w3.eth.get_transaction_count(from_account.address),
    "gas": 21000,
    "gasPrice": 250000000,
    "value": value
  }, from_account.key)

  txn_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
  return txn_hash.hex()

def uploadKYC(kyhash, from_account):
  estimate_gas = val_contract.functions["uploadKYC"](kyhash).estimate_gas()
  encoded_data = val_contract.encodeABI(fn_name="uploadKYC", args=[kyhash])
  signed_transaction = w3.eth.account.sign_transaction({
    "from": from_account.address,
    "to": val_addr,
    "nonce": w3.eth.get_transaction_count(from_account.address),
    "gas": estimate_gas,
    "gasPrice": 250000000,
    "value": 0,
    "data": encoded_data
  }, from_account.key)

  txn_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
  return txn_hash.hex()

def propose(candidate_addr, owner_account):
  encoded_data = val_contract.encodeABI(fn_name="propose", args=[candidate_addr])
  signed_transaction = w3.eth.account.sign_transaction({
    "from": owner_account.address,
    "to": val_addr,
    "nonce": w3.eth.get_transaction_count(owner_account.address),
    "gas": 470000,
    "gasPrice": 250000000,
    "value": 10000000000000000000000000,
    "data": encoded_data
  }, owner_account.key)

  txn_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
  return txn_hash.hex()

def eth_getTransactionByHash(hash):
  res = requests.post(
    NODE_RPC, 
    json={
      "method":"eth_getTransactionByHash",
      "params":[hash],
      "id": 1,
      "jsonrpc":"2.0"
    }
  )
  return res.json()["result"]

def eth_sendRawTransaction(raw_transaction):
  res = requests.post(
    NODE_RPC, 
    json={
      "method":"eth_sendRawTransaction",
      "params":[raw_transaction.hex()],
      "id": 1,
      "jsonrpc":"2.0"
    }
  )
  return res.json()["result"]

def eth_getTransactionByBlockNumberAndIndex(blockNumber, index):
  res = requests.post(
    NODE_RPC, 
    json={
      "method":"eth_getTransactionByBlockNumberAndIndex",
      "params":[hex(blockNumber), hex(index)],
      "id": 1,
      "jsonrpc":"2.0"
    }
  )
  return res.json()["result"]

def eth_getBlockTransactionCountByNumber(blockNumber):
  res = requests.post(
    NODE_RPC, 
    json={
      "method":"eth_getBlockTransactionCountByNumber",
      "params":[hex(blockNumber)],
      "id": 1,
      "jsonrpc":"2.0"
    }
  )
  return res.json()["result"]

def eth_getBlockByNumber(blockNumber):
  res = requests.post(
    NODE_RPC, 
    json={
      "method":"eth_getBlockByNumber",
      "params":[hex(blockNumber), False],
      "id": 1,
      "jsonrpc":"2.0"
    }
  )
  return res.json()["result"]



if __name__ == "__main__":
  args = parse_args()
  num_masternodes = int(args.number)
  if num_masternodes > 3122:
    print("Too many requested masternodes. Maximum amount is 3122")
    sys.exit(1)
  
  # 1. transfer entire amount of XDC from rich account to owner account
  txn1 = transfer(12000000000000000000000000 * num_masternodes, rich_account, owner_account.address)
  sleep(2)

  # 2. submit kyhash from owner account to add it into whitelist
  txn2 = uploadKYC("test", owner_account)
  sleep(2)

  txns = []
  for i in range(num_masternodes):
    with open(f"{MASTERNODE_KEY_FOLDER}/GENERATED_KEY_{i+1}.txt", "w") as f:
      masternode_account = Account.create(os.urandom(64))
      f.write(masternode_account.key.hex()[2:])
      txn = propose(masternode_account.address, owner_account)
      txns.append(txn)
  
  with open(TRANSACTION_RECORD, "w") as f:
    f.write(f"{txn1}\n")
    f.write(f"{txn2}\n")
    for txn in txns:
      f.write(f"{txn}\n")
