FROM node:20-slim AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install -g npm@11 && npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build


FROM node:20-slim AS runner

# Install yt-dlp, ffmpeg, and openssl (for Prisma)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    ffmpeg \
    curl \
    ca-certificates \
    openssl \
    && update-ca-certificates \
    && curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install -g npm@11 && npm ci --omit=dev

# Generate Prisma client for the actual runtime platform (avoids cross-arch binary issues)
COPY prisma ./prisma
RUN npx prisma generate

# Copy compiled app
COPY --from=builder /app/dist ./dist

ENV NODE_ENV=production

EXPOSE 8000

CMD ["sh", "-c", "node --stack-trace-limit=50 node_modules/.bin/prisma migrate deploy && node --stack-trace-limit=50 dist/index.js"]
