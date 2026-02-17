FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app

# Copy only pubspec.yaml (not .lock)
COPY pubspec.yaml ./

# Get dependencies fresh in the container
RUN flutter pub get

# Copy the rest of the code
COPY . .

# Build the web app
ARG ENVOY_HOST
RUN flutter build web --release --dart-define=ENVOY_HOST=${ENVOY_HOST}

# Use nginx to serve the built app
FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]