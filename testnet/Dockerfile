FROM golang:1.14

WORKDIR /work

RUN \
    apt-get update && apt-get install -y git build-essential && \
    git clone https://github.com/XinFinOrg/XDPoSChain.git xdcchain && \
	(cd xdcchain && git checkout --detach e7e8b0e6ae773c35326ef945994002d852a17405 && make)

RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC && \
    rm -rf xdcchain

EXPOSE 8555
EXPOSE 8556
EXPOSE 30304

ENTRYPOINT ["bash","/work/start-apothem.sh"]
