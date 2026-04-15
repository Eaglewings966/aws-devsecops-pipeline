# Stage 1 — Dependencies
FROM node:22-alpine AS dependencies

WORKDIR /app

# Copy package files first for layer caching
COPY app/package.json app/package-lock.json ./

# Install production dependencies only
RUN npm ci --omit=dev && \
    npm cache clean --force

# Stage 2 — Production image
FROM node:22-alpine AS production

# Security — create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy only production dependencies from build stage
COPY --from=dependencies --chown=appuser:appgroup /app/node_modules ./node_modules

# Copy application source
COPY --chown=appuser:appgroup app/ .

# Security — run as non-root user
USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=10s \
            --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

ENV NODE_ENV=production

CMD ["node", "index.js"]
