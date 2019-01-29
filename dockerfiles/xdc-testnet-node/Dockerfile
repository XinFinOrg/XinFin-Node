FROM golang:1.11

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoS-TestNet-Apothem.git xdcchain && \
	(cd xdcchain && git checkout --detach 1130199b95301c8696e1fc94eccb7e0549c8b262 && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]
