# Multi-stage build for Nuxt 4 frontend
# Stage 1: Build with Node.js
FROM node:22-alpine AS build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Public URL of the API, baked into the static build
# (docker build --build-arg NUXT_PUBLIC_BACKEND_BASE_URL=https://events.example.com).
# Unset keeps the nuxt.config default, http://localhost:8080.
ARG NUXT_PUBLIC_BACKEND_BASE_URL
ENV NUXT_PUBLIC_BACKEND_BASE_URL=${NUXT_PUBLIC_BACKEND_BASE_URL}

# Build the application
RUN npm run build

# Stage 2: Production image with Nginx
FROM nginx:alpine

# Copy built application from build stage
COPY --from=build /app/.output/public /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]