FROM node:20-slim

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY . .

RUN mkdir -p /data

ENV DB_PATH=/data/kawabel.db
ENV PORT=3001

EXPOSE 3001

CMD ["node", "index.js"]
