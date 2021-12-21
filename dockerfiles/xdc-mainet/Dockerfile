FROM golang:1.14

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoSChain.git xdcchain && \
	(cd xdcchain && git checkout --detach 621555993ed5a787dcf0f8e64567f270a73f8d7e && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8545
EXPOSE 30303

ENTRYPOINT ["/work/start-node.sh"]
