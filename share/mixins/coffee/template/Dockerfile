FROM node:4.4
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json /usr/src/app/

RUN npm install
RUN npm install coffee-script -g

{{#include}}
COPY {{.}}/ /usr/src/app/{{.}}
{{/include}}

CMD [ "npm", "start" ]

EXPOSE {{port}}
