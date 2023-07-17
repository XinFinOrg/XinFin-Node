# Address Creator

Use this script to create new xdc private key and address.
Keys will be saved at `keys.json` if env `FILE=true`

## Docker Run
### interactive mode
```
docker build -t address-creator . && docker run -it address-creator 

```

### script mode 
```
# Linux like Command
docker build -t address-creator . && docker run -e NUMBER_OF_KEYS=3 -e FILE=true -v "$(pwd):/work/output" -it address-creator 

# Windows like Command
docker build -t address-creator . && docker run -e NUMBER_OF_KEYS=3 -e FILE=true -v "%cd%:/work/output" -it address-creator
```

### Output
```
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