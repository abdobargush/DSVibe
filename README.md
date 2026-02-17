# DSVibe - Distributed Systems Projects

This repository contains two distributed systems projects developed as assignments for the Distributed Systems MSC course. Both projects are containerized with Docker and deployed on Google Kubernetes Engine (GKE).

> **Development Approach:** These projects were built using the **Vibe Coding** methodology, leveraging AI-driven agentic workflows for rapid architecture design, implementation, and deployment.

## Projects Overview

### 1. [Temperature Converter (TempConv)](./TempConv/README.md)
A full-stack temperature conversion application demonstrating gRPC communication between services.

*   **Architecture**:
    *   **Backend**: Go service implementing gRPC API.
    *   **Frontend**: Flutter Web application.
    *   **Communication**: gRPC-Web via Envoy Proxy (LoadBalancer).
    *   **Deployment**: Hosted on GKE with external access.
*   **Key Features**:
    *   gRPC Health Checks.
    *   Envoy Proxy for gRPC-Web support.
    *   Multi-platform Docker builds (AMD64/ARM64).

### 2. [MexPoker (Texas Hold'em Evaluator)](./MexPoker/README.md)
A poker hand evaluation and probability calculation tool using Monte Carlo simulations.

*   **Architecture**:
    *   **Backend**: Go REST API server.
    *   **Frontend**: Flutter Web application serving via Nginx.
    *   **Communication**: REST API (HTTP/JSON).
    *   **Proxy**: Nginx reverse proxy to route `/api` requests to the internal backend service.
*   **Key Features**:
    *   Hand Evaluation & Comparison.
    *   Win Probability Calculation (Monte Carlo).
    *   Internal ClusterIP backend with Nginx-proxied frontend.

## Deployment Summary

Both projects follow a similar deployment strategy on GKE:

1.  **Containerization**: Dockerfiles for Backend and Frontend.
2.  **Registry**: Images pushed to Google Container Registry (GCR).
3.  **Orchestration**: Kubernetes manifests for Deployments and Services.
4.  **Exposure**: Frontends exposed via LoadBalancer services.

## Prerequisites

To deploy or run these projects locally, you typically need:

*   **Docker Desktop**
*   **Google Cloud SDK (`gcloud`)**
*   **Kubernetes CLI (`kubectl`)**
*   **Go 1.21+**
*   **Flutter 3.16+**

## Quick Start

Navigate to the respective project directories for detailed setup and deployment instructions:

```bash
# For Temperature Converter
cd TempConv
cat README.md

# For MexPoker
cd MexPoker
cat README.md
```
