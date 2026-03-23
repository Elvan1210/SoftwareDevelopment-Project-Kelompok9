# Build stage
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

# Production stage
FROM node:18-alpine

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Set environment variables for production
ENV NODE_ENV=production
ENV PORT=3000

# Expose API port
EXPOSE 3000

# Start gracefully
CMD ["node", "index.js"]
