FROM node:4.3
RUN mkdir -p /usr/app
WORKDIR /usr/app

COPY package.json /usr/app/
RUN npm install
COPY lib/ /usr/app/lib
COPY env/ /usr/app/env
COPY bin/ /usr/app/bin
CMD [ "npm start", "production" ]

EXPOSE 80
