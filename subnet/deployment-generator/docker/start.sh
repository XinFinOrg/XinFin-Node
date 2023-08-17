#!bin/bash
node /app/script/gen.js
puppeth --file /app/generated/genesis_input.yml --out /app/generated/

if [[ -z "${SLEEP}" ]]; then
    echo "sleep ${SLEEP}"
    sleep ${SLEEP}
else
    echo "docker run finished"
fi