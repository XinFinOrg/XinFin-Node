set mypath=%cd%

if not exist "%mypath%\work" mkdir "%mypath%\work"

copy NUL "%mypath%\work\password.txt"
echo f | xcopy /f /y ..\genesis.json %mypath%\work\genesis.json

echo "Creating Coinbase Account"
XDC account new --password "%mypath%\work\password.txt" --datadir "%mypath%\work\xdcchain"

echo "Initalizing Genesis"
XDC --datadir "%mypath%\work\xdcchain" init "%mypath%\work\genesis.json"

echo "Starting Masternode"
XDC --syncmode "full" --datadir "%mypath%\work\xdcchain" --ethstats "Windows:xinfin_network_stats@stats.testnet.xinfin.network:3001" --networkid 1993 -port 30303 --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts "*" --mine --gasprice "1" --targetgaslimit "420000000" --verbosity 3 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS  --bootnodes "enode://1c20e6b46ce608c1fe739e78611225b94e663535b74a1545b1667eac8ff75ed43216306d123306c10e043f228e42cc53cb2728655019292380313393eaaf6e23@5.152.223.197:30303"
