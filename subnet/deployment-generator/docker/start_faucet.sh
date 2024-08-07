#!/bin/bash


json=$(jq -r .Grandmaster.PrivateKey temp_mount/keys.json)
# json=$(jq .Grandmaster.not_avail temp_mount/keys.json)
echo $json

if [[ $json != "null" ]]; then
  echo "exists!"
fi

# node /app/src/gen.js 


if [[ $json == "0xdfc35b23e7afb972c7f9b8600e3fd58d15b4f7e2c50d4bffa60b955a9f03350b" ]]; then
  echo "quotes!!"
fi