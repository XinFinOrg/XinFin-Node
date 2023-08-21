
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

FROM node:18.15

WORKDIR /app

COPY --from=builder /go/XDC-Subnet/build/bin/puppeth /bin/puppeth
COPY --from=builder /go/XDC-Subnet/mainnet_contract /app/contract

#this step here for caching
RUN cd contract && yarn

COPY ./script /app/script
COPY ./docker/start.sh /app/start.sh
COPY ./docker/deploy_csc.sh /app/deploy_csc.sh

RUN chmod +x /app

RUN cd script && npm install


ENTRYPOINT ["bash","/app/start.sh"]
