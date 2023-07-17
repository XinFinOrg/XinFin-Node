FROM golang:1.14

WORKDIR /work

RUN apt-get update && apt-get install -y git build-essential

RUN git clone https://github.com/XinFinOrg/XDPoSChain.git xdcchain && cd xdcchain && git checkout dev-upgrade

RUN mv /work/xdcchain/common/constants/constants.go.devnet /work/xdcchain/common/constants.go
RUN cd /work/xdcchain/ && make
RUN cp /work/xdcchain/build/bin/XDC /usr/bin && chmod +x /usr/bin/XDC

EXPOSE 8545
EXPOSE 8546
EXPOSE 30304
EXPOSE 30303

ENTRYPOINT ["bash","/work/start.sh"]
