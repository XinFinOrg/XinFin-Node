curl --location 'http://localhost:8545' \
--header 'Content-Type: application/json' \
--data '{"jsonrpc":"2.0","method":"XDPoS_getV2BlockByNumber","params":["latest"],"id":1}'