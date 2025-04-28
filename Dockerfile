# syntax=docker/dockerfile:1
ARG NODE_VERSION=22.13.1
FROM node:${NODE_VERSION}-slim AS base
WORKDIR /usr/src/app

# Install dependencies in a separate build stage for caching and security
FROM base AS deps
# Copy only package.json and package-lock.json for dependency installation
COPY --link package.json package-lock.json ./
# Use npm ci for deterministic, clean installs and cache npm hhvkh
RUN --mount=type=cache,target=/root/.npm \
    npm ci --production

# Final runtime image
FROM base AS final
# Create a non-root user and group
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copy installed node_modules and app source
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY --link . .

# Do not copy .env or any secrets (ensure .env is in .dockerignore)

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Set permissions for the non-root user
RUN chown -R appuser:appgroup /usr/src/app
USER appuser

EXPOSE 8001
CMD ["npm", "start"]
