FROM node:18.15

WORKDIR /app

COPY ./src /app/src
COPY ./scripts /app/scripts
COPY ./docker/start.sh /app/start.sh

RUN chmod +x /app/start.sh

RUN cd src && npm install

ENTRYPOINT ["bash","/app/start.sh"]
