# Production multi-stage Dockerfile for PAWS360 frontend (Next.js)
# Builds the app and runs it in a minimal Node runtime.

FROM node:20-alpine AS deps
WORKDIR /app

# Copy package manifests and install dependencies (use npm ci for reproducible installs)
COPY package.json package-lock.json* ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app

# Reuse installed deps, copy source and build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Copy built app and node_modules only
COPY --from=builder /app .

EXPOSE 3000

# Use the standard start script defined in package.json (next start)
CMD ["npm", "run", "start"]
