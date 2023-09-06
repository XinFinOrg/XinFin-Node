
FROM golang:1.14 as builder

ARG SUBNET_BRANCH=master    

RUN git clone https://github.com/XinFinOrg/XDC-Subnet

#it is called 'BRANCH' but commits also work
RUN cd XDC-Subnet && git checkout ${SUBNET_BRANCH} &&  make puppeth







FROM node:18.15

ARG SUBNET_BRANCH=master    
ARG IMAGE_NAME=latest
#inject build arg as ENV
ENV SUBNET_BRANCH=${SUBNET_BRANCH}
ENV IMAGE_NAME=${IMAGE_NAME}
RUN echo SUBNET_BRANCH=${SUBNET_BRANCH}
RUN echo IMAGE_NAME=${IMAGE_NAME}

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
