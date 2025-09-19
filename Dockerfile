# Build stage
FROM node:16.17.0-alpine AS builder
WORKDIR /app

# Copy package files
COPY package.json ./
COPY yarn.lock* ./

# Install dependencies
RUN yarn install

# Copy source code
COPY . .

# SECURITY: Use ARG only during build - does not persist in final image
ARG TMDB_API_KEY
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"

# Build the application with API key as build-time variable only
# The API key is embedded in the built static files but not in ENV vars
RUN VITE_APP_TMDB_V3_API_KEY=${TMDB_API_KEY} yarn build

# Production stage
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

# Clean nginx default files
RUN rm -rf ./*

# Copy built application from builder stage
COPY --from=builder /app/dist .

# Expose port 80
EXPOSE 80

# Start nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]