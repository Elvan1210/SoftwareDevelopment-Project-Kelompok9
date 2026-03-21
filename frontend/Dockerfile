# Build stage
FROM ubuntu:22.04 AS builder

# Install dependencies needed for Flutter
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Setup Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Switch to App directory
WORKDIR /app
COPY . .

# Build the Web artifact
RUN flutter clean
RUN flutter pub get
RUN flutter build web --release

# Production stage (Serve Web Build)
FROM nginx:alpine

# Copy built flutter web files to Nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose Web port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
