FROM node:20-slim

# Install yt-dlp, ffmpeg, and libssl (required by Prisma query engine)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    ffmpeg \
    curl \
    ca-certificates \
    libssl-dev \
    && update-ca-certificates \
    && curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install -g npm@11 && npm ci

COPY prisma ./prisma
COPY prisma.config.ts ./
COPY tsconfig.json ./
COPY src ./src
RUN npx prisma generate
RUN npm run build && npm prune --omit=dev

ENV NODE_ENV=production

EXPOSE 8000

CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
