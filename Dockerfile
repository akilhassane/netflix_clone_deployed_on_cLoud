# Build stage
FROM node:16.17.0-alpine AS builder
WORKDIR /app

# Install dependencies
COPY ./package.json .
COPY ./yarn.lock .
RUN yarn install

# Copy source code
COPY . .

# Use build secrets for sensitive data (more secure than ARG/ENV)
RUN --mount=type=secret,id=tmdb_api_key \
    export VITE_APP_TMDB_V3_API_KEY=$(cat /run/secrets/tmdb_api_key) && \
    export VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3" && \
    yarn build

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