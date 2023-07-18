const fs = require('fs');
const ethers = require('ethers');
const crypto = require('crypto');
const prompt = require('prompt-sync')();

const NUMBER_OF_KEYS = process.env.NUMBER_OF_KEYS;
const FILE = process.env.FILE;

let times;

if (!NUMBER_OF_KEYS) {
    times = prompt('How many private keys you want to create: ');
} else {
    times = Number(NUMBER_OF_KEYS);
}

const keys = {}
for ( let i = 0; i < times; i++) {
    const key = `key${i}`
    const privateKey = crypto.randomBytes(32).toString('hex');
    const wallet = new ethers.Wallet(privateKey);
    keys[key] = {
        "PrivateKey": privateKey,
        "0x":wallet.address,
        "xdc": wallet.address.replace(/^0x/i, "xdc"),
    }
}
console.log(keys);

if (FILE) {
    const filePath = 'output/keys.json';
    const jsonData = JSON.stringify(keys, null, 2);

    fs.writeFile(filePath, jsonData, (err) => {
        if (err) {
          console.error('Error writing file:', err);
          return;
        }
        console.log('keys saved to file:', filePath);
    });
}