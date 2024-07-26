FROM node:18.15

WORKDIR /app

COPY ./src /app/src
COPY ./docker/start.sh /app/start.sh

RUN chmod +x /app/start.sh

RUN cd src && npm install

RUN cd src/faucet && npm install

ENTRYPOINT ["bash","/app/start.sh"]
