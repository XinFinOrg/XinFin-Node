# Address Creator

Use this script to create new xdc private key and address

## Docker Run
```
docker build -t address-creator . && docker run -it address-creator 
...
...
How many private keys you want to create: 2
Private Key 0 : 0x1
0x Address: 0x1
XDC Address: xdc1

Private Key 1 : 0x2
0x Address: 0x2
XDC Address: xdc2
```

## Native Run
```
npm i
node address-creator.js
How many private keys you want to create: 2

Private Key 0 : 0x1
0x Address: 0x1
XDC Address: xdc1

Private Key 1 : 0x2
0x Address: 0x2
XDC Address: xdc2
```