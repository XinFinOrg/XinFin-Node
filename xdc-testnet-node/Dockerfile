FROM golang:1.9.4-stretch

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone -b "testnet" https://github.com/XinFinOrg/XDCChain.git gxdcchain && \
    (cd gxdcchain && make gxdc)

RUN cp gxdcchain/work/bin/gxdc /usr/bin && chmod +x /usr/bin/gxdc && \
    rm -rf gxdcchain

COPY ./genesis.json /work/genesis.json
COPY ./start-node.sh /work/start-node.sh
COPY ./bootnodes.txt /work/bootnodes.txt
RUN chmod +x /work/start-node.sh

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]
