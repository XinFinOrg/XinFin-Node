FROM golang:1.14

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoSChain.git xdcchain && \
	(cd xdcchain && git checkout --detach f9fa3a8a0711dddeec4559a885a8e8bd992f4791 && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]
