FROM golang:1.11

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoS-TestNet-Apothem.git xdcchain && \
	(cd xdcchain && git checkout --detach f7cf39e7d9f26a4c1859f263016cc86fb3a9ebd7 && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]
