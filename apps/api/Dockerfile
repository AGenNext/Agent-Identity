# Container image for the Agent Identity API (apps/api).
# Build from this directory:  docker build -t ghcr.io/agennext/agent-identity-api:latest apps/api
FROM node:20-alpine

WORKDIR /app

# Install production dependencies (no lockfile in the workspace yet).
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

COPY src ./src

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Run as the built-in non-root node user.
USER node

CMD ["node", "src/index.js"]
