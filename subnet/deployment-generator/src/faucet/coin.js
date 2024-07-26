const dotenv = require('dotenv');
dotenv.config({ path: `${__dirname}/coin.env` });
const { Web3 } = require('web3');
const EthereumTx = require('ethereumjs-tx').Transaction;


var dest = process.env.DEST_WALLET
var num_coin = process.env.TRANSFER_AMOUNT
var url = process.env.SUBNET_RPC_URL // ip and port of the subnet RPC
var grandPrivateKey = Buffer.from(
  process.env.GRANDMASTER_PK,
  'hex',
);

var web3 = new Web3(url);
var grandAccount = web3.eth.accounts.privateKeyToAccount('0x'+grandPrivateKey.toString('hex'));
var grandAddr = grandAccount.address;
const value = 1e18*num_coin //in wei
var gasPrice = 250000000;

async function main() {
  var nonce = await web3.eth.getTransactionCount(grandAddr);
  var txParams = {
      nonce: Number(nonce),
      gasPrice: gasPrice,
      gasLimit: 21000,
      to: dest,
      value: value,
  };
  const tx = new EthereumTx(txParams, { 'chain': 'mainnet', 'hardfork': 'homestead' }); // hardfork homestead is critical to make it work!
  tx.sign(grandPrivateKey);
  const serializedTx = '0x' + tx.serialize().toString('hex');
  web3.eth.sendSignedTransaction(serializedTx)
      .on('transactionHash', hash => console.log('txHash:', hash))
      .on('receipt', receipt => console.log(receipt))
      .on('error', console.error);
}

main().then().catch(console.error) 