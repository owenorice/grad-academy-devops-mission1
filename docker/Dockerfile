# Builds the Social Hub app image.
# The build context (set in docker-compose.yml) holds server.js + package.json.
FROM node:18-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./

EXPOSE 80
CMD ["node", "server.js"]
