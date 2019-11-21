FROM golang:1.12

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoS-TestNet-Apothem.git xdcchain && \
	(cd xdcchain && git checkout --detach 72138a0bd20a81a377f42bd38cd536d68fe730a1 && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-testnetnode.sh"]
