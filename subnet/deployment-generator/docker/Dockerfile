
FROM golang:1.14 as builder

#use node base image since it can already run the go binary
# RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &&\  
#     apt-get install -y nodejs
# RUN apt-get update && apt-get install -y build-essential 
# RUN npm install -g yarn

RUN git clone https://github.com/XinFinOrg/XDC-Subnet

ARG SUBNET_BRANCH=easy-genesis        
#it is called 'BRANCH' but commits also work
RUN cd XDC-Subnet && git checkout ${SUBNET_BRANCH} &&  make puppeth

FROM node:18

WORKDIR /app

RUN ls && ls /app

COPY --from=builder /go/XDC-Subnet/build/bin/puppeth /bin/puppeth
COPY --from=builder /go/XDC-Subnet/mainnet_contract /app/contract

RUN chmod +x /app

COPY . /app

RUN cd script && npm install
RUN cd contract && yarn

ENTRYPOINT ["bash","/app/docker/start.sh"]
