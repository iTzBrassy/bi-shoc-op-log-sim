FROM node:12.18.1
ENV NODE_ENV=production

WORKDIR /app

COPY ["package.json", "package-lock.json*", "index.js", "config.json", "./"]

RUN npm install 

CMD [ "npm", "start" ]