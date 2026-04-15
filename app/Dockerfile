# Stage 1 — Dependencies
FROM node:22-alpine AS dependencies

WORKDIR /app

# Copy package files first for layer caching
COPY app/package.json app/package-lock.json ./

# Install production dependencies only
RUN npm ci --omit=dev && \
    npm cache clean --force

# Stage 2 — Production image
FROM gcr.io/distroless/nodejs22-debian12:nonroot AS production

WORKDIR /app

# Copy only production dependencies from build stage
COPY --from=dependencies --chown=nonroot:nonroot /app/node_modules ./node_modules

# Copy application source
COPY --chown=nonroot:nonroot app/ .

EXPOSE 3000

ENV NODE_ENV=production

CMD ["index.js"]
