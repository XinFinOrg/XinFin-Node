const ethers = require('ethers');  
const crypto = require('crypto');
const prompt = require('prompt-sync')();

const times = prompt('How many private keys you want to create: ');
for ( let i = 0; i < times; i++) {
    const id = crypto.randomBytes(32).toString('hex');
    const privateKey = "0x"+id;
    console.log("Private Key", i, ":", privateKey);
    const wallet = new ethers.Wallet(privateKey);
    console.log("0x Address: " + wallet.address);
    console.log("XDC Address: " + wallet.address.replace(/^0x/i, "xdc"));
    console.log();
}