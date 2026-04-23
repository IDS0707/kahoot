# ── Stage 1: builder ─────────────────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency manifests first (better layer caching)
COPY package*.json ./

# Install production deps only
RUN npm ci --only=production

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM node:18-alpine

WORKDIR /app

# Copy installed node_modules from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy application source
COPY . .

# Expose game server port
EXPOSE 3000

# Run as non-root for security
USER node

CMD ["node", "server.js"]
