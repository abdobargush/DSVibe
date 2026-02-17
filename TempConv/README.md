# Temperature Converter Service

A full-stack temperature conversion application with gRPC backend (Go) and Flutter web frontend, containerized with Docker and deployed on Google Kubernetes Engine (GKE).

## Architecture Overview

- **Backend**: Go service with gRPC API
- **Frontend**: Flutter web application
- **Communication**: gRPC-Web (Envoy proxy for browser compatibility)
- **Containerization**: Docker
- **Orchestration**: Kubernetes (GKE)
- **Load Testing**: k6

## Project Structure

```
temperature-converter/
├── backend/
│   ├── proto/
│   │   └── temperature.proto
│   ├── server/Ple
│   │   └── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   └── generated/
│   │       └── temperature.pb.dart
│   ├── web/
│   │   └── index.html
│   ├── pubspec.yaml
│   └── Dockerfile
├── envoy/
│   ├── envoy.yaml
│   └── Dockerfile
├── k8s/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── envoy-deployment.yaml
│   ├── envoy-service.yaml
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
├── load-testing/
│   └── load-test.js
├── docker-compose.yaml
└── README.md
```

---

## Phase 1: Setup Development Environment

### Prerequisites

```bash
# Install Go (1.21+)
# Download from https://go.dev/dl/

# Install Flutter (3.16+)
# Download from https://flutter.dev/docs/get-started/install

# Install Docker
# Download from https://www.docker.com/products/docker-desktop

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install gcloud CLI
# Download from https://cloud.google.com/sdk/docs/install

# Install k6
# Download from https://k6.io/docs/getting-started/installation/

# Install protoc (Protocol Buffers compiler)
# Download from https://github.com/protocolbuffers/protobuf/releases
```

### Install gRPC Tools

```bash
# Go gRPC plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Dart gRPC plugin
dart pub global activate protoc_plugin
```

---

## Phase 2: Backend Development (Go + gRPC)

### Step 1: Create Proto Definition

Create `backend/proto/temperature.proto`:

```protobuf
syntax = "proto3";

package temperature;

option go_package = "github.com/yourusername/temperature-converter/backend/proto";

service TemperatureConverter {
  rpc ConvertTocelsius(TemperatureRequest) returns (TemperatureResponse);
  rpc ConvertToFahrenheit(TemperatureRequest) returns (TemperatureResponse);
}

message TemperatureRequest {
  double value = 1;
}

message TemperatureResponse {
  double value = 1;
  string unit = 2;
}
```

### Step 2: Generate Go Code from Proto

```bash
cd backend
mkdir -p proto

# Generate Go code
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/temperature.proto
```

### Step 3: Initialize Go Module

```bash
cd backend
go mod init github.com/yourusername/temperature-converter/backend
go get google.golang.org/grpc
go get google.golang.org/protobuf
```

### Step 4: Create Go Server

Create `backend/server/main.go`:

```go
package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"

	pb "github.com/yourusername/temperature-converter/backend/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"
)

type server struct {
	pb.UnimplementedTemperatureConverterServer
}

func (s *server) ConvertToCelsius(ctx context.Context, req *pb.TemperatureRequest) (*pb.TemperatureResponse, error) {
	celsius := (req.Value - 32) * 5 / 9
	log.Printf("Converting %.2f°F to %.2f°C", req.Value, celsius)
	return &pb.TemperatureResponse{
		Value: celsius,
		Unit:  "Celsius",
	}, nil
}

func (s *server) ConvertToFahrenheit(ctx context.Context, req *pb.TemperatureRequest) (*pb.TemperatureResponse, error) {
	fahrenheit := (req.Value * 9 / 5) + 32
	log.Printf("Converting %.2f°C to %.2f°F", req.Value, fahrenheit)
	return &pb.TemperatureResponse{
		Value: fahrenheit,
		Unit:  "Fahrenheit",
	}, nil
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "50051"
	}

	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterTemperatureConverterServer(s, &server{})
	
	// Register health service for Kubernetes readiness probes
	healthServer := health.NewServer()
	grpc_health_v1.RegisterHealthServer(s, healthServer)
	healthServer.SetServingStatus("", grpc_health_v1.HealthCheckResponse_SERVING)
	
	reflection.Register(s)

	log.Printf("Server listening on port %s", port)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
```

### Step 5: Create Backend Dockerfile

Create `backend/Dockerfile`:

```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Build for Linux AMD64 (required for GKE)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates wget

WORKDIR /root/

COPY --from=builder /app/server .

# Install grpc_health_probe for Kubernetes readiness probes
RUN GRPC_HEALTH_PROBE_VERSION=v0.4.19 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe

EXPOSE 50051

CMD ["./server"]
```

### Step 6: Test Backend Locally

```bash
cd backend
go run server/main.go
```

---

## Phase 3: Frontend Development (Flutter Web)

### Step 1: Create Flutter Project

```bash
flutter create frontend
cd frontend
```

### Step 2: Add Dependencies

Edit `frontend/pubspec.yaml`:

```yaml
name: frontend
description: Temperature Converter Frontend
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  grpc: ^3.2.4
  protobuf: ^3.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
```

### Step 3: Generate Dart Code from Proto

```bash
cd frontend
mkdir -p lib/generated

# Copy proto file
cp ../backend/proto/temperature.proto lib/generated/

# Generate Dart code
protoc --dart_out=grpc:lib/generated -Ilib/generated lib/generated/temperature.proto
```

### Step 4: Create Flutter UI

Create `frontend/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'generated/temperature.pbgrpc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _controller = TextEditingController();
  String _result = '';
  bool _isCelsiusToFahrenheit = true;
  late TemperatureConverterClient _client;

  @override
  void initState() {
    super.initState();
    _initGrpcClient();
  }

  void _initGrpcClient() {
    // Get envoy host from environment or use default
    // When built with Docker, we pass ENVOY_HOST as a dart-define
    const envoyHost = String.fromEnvironment('ENVOY_HOST');
    final host = envoyHost.isNotEmpty ? envoyHost : (Uri.base.host.isEmpty ? 'localhost' : Uri.base.host);
    final port = const int.fromEnvironment('ENVOY_PORT', defaultValue: 8080);
    
    // For web, use http protocol
    final envoyUrl = 'http://$host:$port';
    
    final channel = GrpcWebClientChannel.xhr(
      Uri.parse(envoyUrl),
    );

    _client = TemperatureConverterClient(channel);
  }

  Future<void> _convert() async {
    final value = double.tryParse(_controller.text);
    if (value == null) {
      setState(() {
        _result = 'Please enter a valid number';
      });
      return;
    }

    try {
      final request = TemperatureRequest()..value = value;
      final response = _isCelsiusToFahrenheit
          ? await _client.convertToFahrenheit(request)
          : await _client.convertToCelsius(request);

      setState(() {
        _result = '${response.value.toStringAsFixed(2)} °${response.unit[0]}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Converter'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Temperature',
                          suffixText: _isCelsiusToFahrenheit ? '°C' : '°F',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('°C to °F'),
                          Switch(
                            value: !_isCelsiusToFahrenheit,
                            onChanged: (value) {
                              setState(() {
                                _isCelsiusToFahrenheit = !value;
                              });
                            },
                          ),
                          const Text('°F to °C'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _convert,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          child: Text('Convert'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _result,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Step 5: Build Flutter Web

```bash
cd frontend
flutter build web
```

### Step 6: Create Frontend Dockerfile

Create `frontend/Dockerfile`:

```dockerfile
# Use ghcr.io/cirruslabs/flutter:stable for better compatibility
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app

# Copy only pubspec.yaml to cache dependencies
COPY pubspec.yaml ./
RUN flutter pub get

COPY . .

# Build the web app with ENVOY_HOST argument
ARG ENVOY_HOST
RUN flutter build web --release --dart-define=ENVOY_HOST=${ENVOY_HOST}

FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## Phase 4: Envoy Proxy (gRPC-Web Bridge)

Envoy is required to translate gRPC-Web calls from the browser to standard gRPC.

### Step 1: Create Envoy Configuration

Create `envoy/envoy.yaml`:

```yaml
admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address:
      protocol: TCP
      address: 0.0.0.0
      port_value: 9901

static_resources:
  listeners:
    - name: listener_0
      address:
        socket_address:
          protocol: TCP
          address: 0.0.0.0
          port_value: 8080
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                codec_type: auto
                stat_prefix: ingress_http
                route_config:
                  name: local_route
                  virtual_hosts:
                    - name: local_service
                      domains: ["*"]
                      routes:
                        - match:
                            prefix: "/"
                          route:
                            cluster: temperature_service
                            timeout: 0s
                            max_stream_duration:
                              grpc_timeout_header_max: 0s
                      cors:
                        allow_origin_string_match:
                          - prefix: "*"
                        allow_methods: GET, PUT, DELETE, POST, OPTIONS
                        allow_headers: keep-alive,user-agent,cache-control,content-type,content-transfer-encoding,custom-header-1,x-accept-content-transfer-encoding,x-accept-response-streaming,x-user-agent,x-grpc-web,grpc-timeout
                        max_age: "1728000"
                        expose_headers: custom-header-1,grpc-status,grpc-message
                http_filters:
                  - name: envoy.filters.http.grpc_web
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.grpc_web.v3.GrpcWeb
                  - name: envoy.filters.http.cors
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.cors.v3.Cors
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: temperature_service
      connect_timeout: 0.25s
      type: logical_dns
      http2_protocol_options: {}
      lb_policy: round_robin
      load_assignment:
        cluster_name: temperature_service
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: backend
                      port_value: 50051
```

### Step 2: Create Envoy Dockerfile

Create `envoy/Dockerfile`:

```dockerfile
FROM envoyproxy/envoy:v1.28-latest

COPY envoy.yaml /etc/envoy/envoy.yaml

CMD /usr/local/bin/envoy -c /etc/envoy/envoy.yaml
```

---

## Phase 5: Local Testing with Docker Compose

### Create docker-compose.yaml

Create `docker-compose.yaml` in the root:

```yaml
version: "3.8"

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "50051:50051"
    environment:
      - PORT=50051

  envoy:
    build:
      context: ./envoy
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
      - "9901:9901"
    depends_on:
      - backend

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - envoy
```

### Run Local Stack

```bash
# Build and run all services
docker-compose up --build

# Access the application at http://localhost
```

---

## Phase 6: Kubernetes Deployment Files

### Backend Deployment

Create `k8s/backend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: temperature-converter
    component: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: temperature-converter
      component: backend
  template:
    metadata:
      labels:
        app: temperature-converter
        component: backend
    spec:
      containers:
        - name: backend
          image: gcr.io/YOUR_PROJECT_ID/temperature-backend:latest
          ports:
            - containerPort: 50051
              name: grpc
          env:
            - name: PORT
              value: "50051"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
          livenessProbe:
            exec:
              command: ["/bin/grpc_health_probe", "-addr=:50051"]
            initialDelaySeconds: 5
          readinessProbe:
            exec:
              command: ["/bin/grpc_health_probe", "-addr=:50051"]
            initialDelaySeconds: 5
```

### Backend Service

Create `k8s/backend-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  labels:
    app: temperature-converter
    component: backend
spec:
  type: ClusterIP
  ports:
    - port: 50051
      targetPort: 50051
      protocol: TCP
      name: grpc
  selector:
    app: temperature-converter
    component: backend
```

### Envoy Deployment

Create `k8s/envoy-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: envoy
  labels:
    app: temperature-converter
    component: envoy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: temperature-converter
      component: envoy
  template:
    metadata:
      labels:
        app: temperature-converter
        component: envoy
    spec:
      containers:
        - name: envoy
          image: gcr.io/YOUR_PROJECT_ID/temperature-envoy:latest
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 9901
              name: admin
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
```

### Envoy Service

Create `k8s/envoy-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: envoy
  labels:
    app: temperature-converter
    component: envoy
spec:
  type: LoadBalancer
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
      name: http
  selector:
    app: temperature-converter
    component: envoy
```

### Frontend Deployment

Create `k8s/frontend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: temperature-converter
    component: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: temperature-converter
      component: frontend
  template:
    metadata:
      labels:
        app: temperature-converter
        component: frontend
    spec:
      containers:
        - name: frontend
          image: gcr.io/YOUR_PROJECT_ID/temperature-frontend:latest
          ports:
            - containerPort: 80
              name: http
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
```

### Frontend Service (LoadBalancer)

Create `k8s/frontend-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: temperature-converter
    component: frontend
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
  selector:
    app: temperature-converter
    component: frontend
```

---

## Phase 7: Google Cloud Setup

### Step 1: Create GCP Project

```bash
# Login to GCP
gcloud auth login

# Create a new project
gcloud projects create YOUR_PROJECT_ID --name="Temperature Converter"

# Set the project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### Step 2: Create GKE Cluster

```bash
# Create GKE cluster
gcloud container clusters create temp-conv-cluster \
    --zone=us-central1-a \
    --num-nodes=3 \
    --machine-type=e2-medium \
    --disk-size=30 \
    --enable-autoscaling \
    --min-nodes=3 \
    --max-nodes=10

# Get cluster credentials
gcloud container clusters get-credentials temp-conv-cluster --zone=us-central1-a
```

### Step 3: Configure Docker for GCR

```bash
# Configure Docker to use gcloud as a credential helper
gcloud auth configure-docker
```

---

## Phase 8: Build and Push Docker Images

### Build Images (Multi-Architecture)

Since GKE nodes are typically Linux/AMD64, we need to build for that platform, especially if developing on Apple Silicon (M1/M2/M3).

**Important:** You must deploy Backend and Envoy *before* building Frontend, as you need the Envoy External IP.

```bash
# 1. Build & Push Backend
docker build --platform linux/amd64 -t gcr.io/YOUR_PROJECT_ID/temperature-backend:latest ./backend
docker push gcr.io/YOUR_PROJECT_ID/temperature-backend:latest

# 2. Build & Push Envoy
docker build --platform linux/amd64 -t gcr.io/YOUR_PROJECT_ID/temperature-envoy:latest ./envoy
docker push gcr.io/YOUR_PROJECT_ID/temperature-envoy:latest
```

### Deploy Backend & Envoy First

```bash
# Apply Backend & Envoy manifests
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/envoy-deployment.yaml
kubectl apply -f k8s/envoy-service.yaml

# Wait for Envoy External IP
kubectl get service envoy --watch
```

### Build & Push Frontend

Once you have the `EXTERNAL-IP` for Envoy (e.g., `34.x.x.x`), build the frontend:

```bash
# Replace 34.x.x.x with your actual Envoy External IP
docker build --build-arg ENVOY_HOST=34.x.x.x --platform linux/amd64 -t gcr.io/YOUR_PROJECT_ID/temperature-frontend:latest ./frontend
docker push gcr.io/YOUR_PROJECT_ID/temperature-frontend:latest
```

---

## Phase 9: Deploy to GKE

### Update Kubernetes Manifests

Replace `YOUR_PROJECT_ID` in all `k8s/*.yaml` files with your actual GCP project ID:

```bash
# On Linux/Mac
sed -i 's/YOUR_PROJECT_ID/your-actual-project-id/g' k8s/*.yaml

# On Mac
sed -i '' 's/YOUR_PROJECT_ID/your-actual-project-id/g' k8s/*.yaml
```

### Apply Kubernetes Manifests

```bash
# Backend and Envoy are already deployed from the previous step.
# Now deploy the frontend:
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Check all deployments
kubectl get deployments
kubectl get services
kubectl get pods
```

### Get Public IP

```bash
# Wait for external IP to be assigned (may take a few minutes)
kubectl get service frontend --watch

# Once EXTERNAL-IP shows an IP address (not <pending>), you can access your app
# The output will look like:
# NAME       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
# frontend   LoadBalancer   10.XX.XXX.XXX   XX.XXX.XXX.XXX   80:XXXXX/TCP   2m

# Copy the EXTERNAL-IP and access it in your browser
```

---

## Phase 10: Load Testing with k6

### Create Load Test Script

Create `load-testing/load-test.js`:

```javascript
import grpc from "k6/net/grpc";
import { check, sleep } from "k6";

const client = new grpc.Client();
client.load(["../backend/proto"], "temperature.proto");

export const options = {
  stages: [
    { duration: "30s", target: 20 }, // Ramp up to 20 users
    { duration: "1m", target: 20 }, // Stay at 20 users
    { duration: "30s", target: 50 }, // Ramp up to 50 users
    { duration: "1m", target: 50 }, // Stay at 50 users
    { duration: "30s", target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    "grpc_req_duration": ["p(95)<500"], // 95% of requests must complete below 500ms
    "grpc_req_failed": ["rate<0.01"], // Error rate must be below 1%
  },
};

export default function () {
  // Get the external IP from environment or use default
  const host = __ENV.ENVOY_HOST || "localhost:8080";

  client.connect(host, {
    plaintext: true,
  });

  // Test Celsius to Fahrenheit conversion
  const celsiusRequest = {
    value: Math.random() * 100,
  };

  const celsiusResponse = client.invoke(
    "temperature.TemperatureConverter/ConvertToFahrenheit",
    celsiusRequest,
  );

  check(celsiusResponse, {
    "celsius conversion status is OK": (r) => r && r.status === grpc.StatusOK,
  });

  // Test Fahrenheit to Celsius conversion
  const fahrenheitRequest = {
    value: Math.random() * 200,
  };

  const fahrenheitResponse = client.invoke(
    "temperature.TemperatureConverter/ConvertToCelsius",
    fahrenheitRequest,
  );

  check(fahrenheitResponse, {
    "fahrenheit conversion status is OK": (r) =>
      r && r.status === grpc.StatusOK,
  });

  client.close();
  sleep(1);
}
```

### Run Load Test

```bash
# Test against local Docker Compose
k6 run ks/load-test.js

# Test against GKE (replace with your external IP)
ENVOY_HOST=YOUR_EXTERNAL_IP:8080 k6 run ks/load-test.js
```

---

## Phase 11: Monitoring and Scaling

### View Logs

```bash
# Backend logs
kubectl logs -l component=backend -f

# Envoy logs
kubectl logs -l component=envoy -f

# Frontend logs
kubectl logs -l component=frontend -f
```

### Scale Deployments

```bash
# Scale backend
kubectl scale deployment backend --replicas=5

# Scale envoy
kubectl scale deployment envoy --replicas=3

# Scale frontend
kubectl scale deployment frontend --replicas=3
```

### Enable Horizontal Pod Autoscaler

```bash
# Autoscale backend based on CPU
kubectl autoscale deployment backend --cpu-percent=70 --min=3 --max=10

# Autoscale envoy
kubectl autoscale deployment envoy --cpu-percent=70 --min=2 --max=5

# Check HPA status
kubectl get hpa
```

---

## Phase 12: Cleanup

### Delete GKE Resources

```bash
# Delete all Kubernetes resources
kubectl delete -f k8s/

# Delete the GKE cluster
gcloud container clusters delete temperature-converter-cluster --zone=us-central1-a

# Delete Docker images from GCR
gcloud container images delete gcr.io/YOUR_PROJECT_ID/temperature-backend:latest
gcloud container images delete gcr.io/YOUR_PROJECT_ID/temperature-envoy:latest
gcloud container images delete gcr.io/YOUR_PROJECT_ID/temperature-frontend:latest
```

---

## Troubleshooting

### Common Issues

**1. Pod not starting:**

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**2. Service not accessible:**

```bash
kubectl get endpoints
kubectl describe service frontend
```

**3. gRPC connection issues:**

- Ensure Envoy is correctly routing to the backend
- Check Envoy logs: `kubectl logs -l component=envoy`
- Verify backend is running: `kubectl get pods -l component=backend`

**4. Image pull errors:**

- Verify images are pushed to GCR: `gcloud container images list`
- Check GKE has permissions to pull from GCR

**5. Load balancer pending:**

- Wait 5-10 minutes for GCP to provision the load balancer
- Check GCP Console → Networking → Load Balancing

---

## Performance Optimization

### Backend Optimization

- Increase replica count for high traffic
- Use connection pooling
- Enable gRPC keepalive

### Frontend Optimization

- Enable NGINX caching
- Use CDN for static assets
- Compress responses

### Envoy Optimization

- Configure connection limits
- Enable request hedging
- Set appropriate timeouts

---

## Security Considerations

1. **Enable TLS/SSL**: Use cert-manager for automatic certificate management
2. **Network Policies**: Restrict pod-to-pod communication
3. **RBAC**: Implement proper role-based access control
4. **Secrets Management**: Use Google Secret Manager for sensitive data
5. **Image Scanning**: Enable GCR vulnerability scanning

---

## CI/CD Integration

Consider setting up automated deployment with:

- **GitHub Actions**: Build and push on commit
- **Cloud Build**: GCP-native CI/CD
- **ArgoCD**: GitOps-based deployment

---

## Cost Optimization

- Use preemptible nodes for non-production
- Right-size your cluster nodes
- Enable cluster autoscaling
- Set resource requests and limits
- Use committed use discounts

---

## Next Steps

1. Add authentication (OAuth2, JWT)
2. Implement caching (Redis)
3. Add observability (Prometheus, Grafana)
4. Set up alerting (PagerDuty, Slack)
5. Implement rate limiting
6. Add API versioning
7. Create Helm charts for easier deployment

---

## Support

For issues and questions:

- GKE Documentation: https://cloud.google.com/kubernetes-engine/docs
- gRPC Documentation: https://grpc.io/docs/
- Flutter Documentation: https://flutter.dev/docs
- k6 Documentation: https://k6.io/docs/

---

## License

MIT License - Feel free to use this project as a template for your own applications.
