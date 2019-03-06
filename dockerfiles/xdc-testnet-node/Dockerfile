FROM golang:1.11

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoS-TestNet-Apothem.git xdcchain && \
	(cd xdcchain && git checkout --detach b4c7e722a19b4de515e5e7b19a2289717d49284c && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]
