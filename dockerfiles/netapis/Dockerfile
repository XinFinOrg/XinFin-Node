FROM node:8

RUN apt-get update && apt-get install -y git

RUN npm install -g pm2

RUN git clone https://github.com/cubedro/eth-net-intelligence-api /netapis && \
    cd /netapis && npm install

WORKDIR /netapis

CMD ["pm2", "start", "--no-daemon", "app.json"]
