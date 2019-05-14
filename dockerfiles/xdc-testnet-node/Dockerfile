FROM golang:1.11

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoS-TestNet-Apothem.git xdcchain && \
	(cd xdcchain && git checkout --detach 8c85c288a9f1b478c0a68b33421e8f4c6cccaccc && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]
