FROM node:20

WORKDIR /work

COPY address-creator.js package.json package-lock.json ./

RUN npm install

CMD [ "node", "address-creator.js" ]
