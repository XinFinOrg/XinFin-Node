process.chdir(__dirname);
const fs = require("fs");
const ethers = require("ethers");
const path = require("path");
const { error } = require("console");
const express = require("express");
const app = express();
const router = express.Router();

const usage =
  "Usage: SUBNET_URL=<subnet_url> node faucet.js <from wallet pk> <to wallet pubkey> <token amount>";
const subnetURL = process.env.SUBNET_URL || "";
if (subnetURL == "") {
  console.log("Invalid SUBNET_URL");
  console.log(usage);
  process.exit();
}
console.log("RPC url:", subnetURL);

const inputs = process.argv;
// console.log("inputs", inputs)

if (inputs.length == 5) {
  try {
    processTransfer(inputs).then(output => {
      // console.log(output)
      process.exit()
    })
  } catch (error) {
    console.log(error);
    console.log(usage);
    process.exit();
  }
} else if (inputs.length == 4) {
  faucetServer(inputs);
} else {
  console.log("Invalid input length");
  console.log(usage);
  process.exit();
}

async function processTransfer(inputs) {
  fromPK = inputs[2];
  toAddress = inputs[3];
  amount = inputs[4];
  const provider = new ethers.JsonRpcProvider(subnetURL);
  const fromWallet = new ethers.Wallet(fromPK, provider);
  let tx = {
    to: toAddress,
    value: ethers.parseEther(amount),
  };

  try{
    await provider._detectNetwork();
  } catch (error){
    throw Error("Cannot connect to RPC")
  }

  let sendPromise = fromWallet.sendTransaction(tx);
  txHash = await sendPromise.then((tx) => {
    return tx.hash;
  });
  console.log("TX submitted, confirming TX execution, txhash:", txHash);

  let receipt;
  let count = 0;
  while (!receipt) {
    count++;
    // console.log("tx receipt check loop", count);
    if (count > 60) {
      throw Error("Timeout: transaction did not execute after 60 seconds");
    }
    await sleep(1000);
    let receipt = await provider.getTransactionReceipt(txHash);
    if (receipt && receipt.status == 1) {
      console.log("Successfully transferred", amount, "subnet token");
      let fromBalance = await provider.getBalance(fromWallet.address);
      fromBalance = ethers.formatEther(fromBalance);
      let toBalance = await provider.getBalance(toAddress);
      toBalance = ethers.formatEther(toBalance);
      console.log("Current balance");
      console.log(fromWallet.address + ":", fromBalance);
      console.log(toAddress + ":", toBalance);
      return {
        fromBalance: fromBalance,
        toBalance: toBalance,
        txHash: txHash
      }
    }
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function faucetServer(inputs) {
  try {
    command = inputs[2];
    fromPK = inputs[3];
    fromWallet = new ethers.Wallet(fromPK);

    if (command != "server") throw Error("Invalid command");
  } catch (error) {
    console.log(error);
    console.log(
      "Usage: SUBNET_URL=<subnet_url> node faucet.js server <from wallet pk>"
    );
  }
  app.set("view engine", "pug");
  app.set("views", path.join(__dirname, "views_faucet"));
  router.use(
    express.urlencoded({
      extended: true,
    })
  );
  app.use(express.static("css"));

  router.get("/", (req, res) => {
    res.render("index", {});
  });

  router.get("/address", (req, res) => {
    const randomWallet = ethers.Wallet.createRandom();
    res.json({
      publicKey: randomWallet.address,
      privateKey: randomWallet.privateKey,
    });
  });

  router.get("/source", (req, res) => {
    res.json({
      source: fromWallet.address,
    });
  });

  router.get("/faucet", async function(req, res) {
    console.log(req.query);
    try {
      toAddress = req.query.dest
      amount = req.query.amount
      if (!ethers.isAddress(toAddress)) throw Error("Invalid destination address")
      if (isNaN(Number(amount)) || parseFloat(amount) <= 0 || amount == "") throw Error("Invalid Amount")
      if (parseFloat(amount) > 1000000) throw Error("Faucet request over 1,000,000 is not allowed")
      let inputs = ["", "", fromPK, toAddress, amount];
      const {fromBalance, toBalance, txHash} = await processTransfer(inputs);
      res.json({
        success: true,
        sourceAddress: fromWallet.address,
        destAddress: toAddress,
        sourceBalance: fromBalance,
        destBalance: toBalance,
        txHash: txHash
      })
    } catch (error) {
      console.log(error);
      console.log(error.message)
      res.json({
        success: false,
        message: error.message 
      })
    }
    // res.json({
    //   "publicKey": randomWallet.address,
    //   "privateKey": randomWallet.privateKey
    // });
  });

  app.use("/", router);

  app.listen(process.env.port || 5211);
  console.log("Running at Port 5211");
  console.log("visit: http://127.0.0.1:5211");
}
