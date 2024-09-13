process.chdir(__dirname);
const { execSync } = require("child_process");
const fs = require("fs");
const ethers = require('ethers');
const express = require("express");
const app = express();
const path = require("path");
const router = express.Router();
 
app.set("view engine", "pug");
app.set("views", path.join(__dirname, "views"));
router.use(express.urlencoded({
  extended: true
})) 
app.use(express.static('css'));

router.get("/", (req, res) => {
  res.render("index", {
  });
});
 
router.post("/submit", (req, res) => {
  gen_env = genGenEnv(req.body)

  fs.writeFileSync(path.join(__dirname, "gen.env"), gen_env, (err) => {
    if (err) {
      console.error(err);
      exit();
    }
  });

  [valid, genOut] = callExec(`node gen.js`);

  console.log()
  console.log(genOut)
  
  if (!valid){
    res.render("submit", { message: "failed, please try again", error: genOut })
    return
  }

  res.render("submit", { message: "Config generation success, please follow instructions in generated/commands.txt" });
  process.exit()
});

router.post("/confirm", (req, res) => {
  console.log(req.body)
  res.render("confirm", { title: "Hey", message: "this is submit" });
});

router.get("/address", (req,res) => {
  const randomWallet = ethers.Wallet.createRandom()
  res.json({
    "publicKey": randomWallet.address,
    "privateKey": randomWallet.privateKey
  });
})
 
app.use("/", router);
app.listen(process.env.port || 5210);
 
console.log("Running at Port 5210");


function callExec(command) {
  try {
    const stdout = execSync(command, { timeout: 200000, encoding: 'utf-8'});
    output = stdout.toString();
    // console.log(output);
    return [true, output]
  } catch (error) {
    // console.log(error)
    return [false, error.stdout]
    throw Error(error.stdout);
  }
}

function genGenEnv(input){
  console.log(input)
 
  let os = ''
  let content_os = ''
  switch (input.osradio){
    case 'os-radio-mac':
      os = 'mac'
      content_os += `\nMAIN_IP=127.0.0.1`
      content_os += `\nNUM_MACHINE=1`
      break
    case 'os-radio-linux':
      os = 'linux'
      content_os += `\nMAIN_IP=${input["text-private-ip"]}`
      if (input["text-public-ip"] != ''){
        content_os += `\nPUBLIC_IP=${input["text-public-ip"]}`  
      }
      if (input["text-num-machine"] != ''){
        content_os += `\nNUM_MACHINE=${input["text-num-machine"]}`
      } else {
        content_os += `\nNUM_MACHINE=1`
      }
      break
  }

  let parentnet = ''
  switch (input.pnradio){
    case 'pn-radio-testnet':
      parentnet = 'testnet'
      break
    case 'pn-radio-devnet':
      parentnet = 'devnet'
      break
    case 'pn-radio-mainnet':
      parentnet = 'mainnet'
      break
  }

  let relayer_mode = ''
  switch (input.rmradio){
    case 'rm-radio-full':
      relayer_mode = 'full'
      break
    case 'rm-radio-lite':
      relayer_mode = 'lite'
      break
  }

  let content_custom_key = ''
  if (input["grandmaster-pk"] != ''){
    content_custom_key += `\nGRANDMASTER_PK=${input["grandmaster-pk"]}`
  }

  let subnet_keys=[]
  let idx = 1
  while ('subnet-key'+idx.toString() in input){
    key = 'subnet-key'+idx.toString()
    subnet_keys.push(input[key])
    idx++
  }
  if (subnet_keys.length > 0){
    key_string = subnet_keys.join(',')
    content_custom_key += `\nSUBNETS_PK=${key_string}`
  }

  let content_version = ''
  if (input["customversion-subnet"] != ''){
    content_version += `\nVERSION_SUBNET=${input["customversion-subnet"]}`
  }
  if (input["customversion-bootnode"] != ''){
    content_version += `\nVERSION_BOOTNODE=${input["customversion-bootnode"]}`
  }
  if (input["customversion-relayer"] != ''){
    content_version += `\nVERSION_RELAYER=${input["customversion-relayer"]}`
  }
  if (input["customversion-stats"] != ''){
    content_version += `\nVERSION_STATS=${input["customversion-stats"]}`
  }
  if (input["customversion-frontend"] != ''){
    content_version += `\nVERSION_FRONTEND=${input["customversion-frontend"]}`
  }
  if (input["customversion-csc"] != ''){
    content_version += `\nVERSION_CSC=${input["customversion-csc"]}`
  }
  if (input["customversion-zero"] != ''){
    content_version += `\nVERSION_ZERO=${input["customversion-zero"]}`
  }

  let content_zero = ''
  if (relayer_mode == 'full' && 'xdczero-checkbox' in input){
    if (input["zmradio"] == 'zm-radio-one'){
      content_zero += '\nXDC_ZERO=one-directional'
    }
    if (input["zmradio"] == 'zm-radio-bi'){
      content_zero += '\nXDC_ZERO=bi-directional'
      content_zero += `\nSUBNET_WALLET_PK=${input["subnet-wallet-pk"]}`
      content_zero += `\nSUBNET_ZERO_WALLET_PK=${input["subnet-zero-wallet-pk"]}` 
    }
    content_zero += `\nPARENTNET_ZERO_WALLET_PK=${input["parentnet-zero-wallet-pk"]}`
    if ('subswap-checkbox' in input){
      content_zero += '\nSUBSWAP=true'
    }
  }

  content=`
NETWORK_NAME=${input["text-subnet-name"]}
NUM_SUBNET=${input["text-num-subnet"]}
OS=${os}
PARENTNET=${parentnet}
PARENTNET_WALLET_PK=${input["parentnet-wallet-pk"]}
RELAYER_MODE=${relayer_mode}
`
  content+=content_os
  content+='\n'
  content+=content_custom_key
  content+='\n'
  content+=content_version
  content+='\n'
  content+=content_zero

  console.log(content)

  return content
}
