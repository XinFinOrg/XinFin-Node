FROM golang:1.9.4-stretch

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDCChain.git xdcchain && \
    (cd xdcchain && git checkout --detach a973741234efe7253db727b2c2cd55fd48d35d3e &&  make xdc)

RUN cp xdcchain/work/bin/xdc /usr/bin && chmod +x /usr/bin/xdc && \
    rm -rf xdcchain

COPY ./genesis.json /work/genesis.json
COPY ./start-node.sh /work/start-node.sh
COPY ./bootnodes.txt /work/bootnodes.txt
RUN chmod +x /work/start-node.sh

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]