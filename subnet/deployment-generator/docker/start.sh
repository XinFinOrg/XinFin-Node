#!bin/bash
node /app/script/gen.js
puppeth --file /app/generated/genesis_input.yml
sleep infinity