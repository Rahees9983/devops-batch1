# Argo Rollouts with Prometheus Analysis Demo

Complete end-to-end demo of Argo Rollouts with Prometheus-based analysis for automatic rollback.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEMO FLOW                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────────┐         ┌──────────────┐                     │
│   │ Load         │ ──────► │ Demo App     │                     │
│   │ Generator    │         │ (v1/v2)      │                     │
│   └──────────────┘         └──────┬───────┘                     │
│                                   │                             │
│                                   │ /metrics                    │
│                                   ▼                             │
│                            ┌──────────────┐                     │
│                            │ Prometheus   │                     │
│                            └──────┬───────┘                     │
│                                   │                             │
│                                   │ PromQL                      │
│                                   ▼                             │
│   ┌──────────────┐         ┌──────────────┐                     │
│   │ Argo         │ ◄────── │ Analysis     │                     │
│   │ Rollouts     │         │ Template     │                     │
│   └──────────────┘         └──────────────┘                     │
│          │                                                      │
│          │ Success? ──► Continue rollout                        │
│          │ Failure? ──► ROLLBACK                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Files Structure

```
argo-rollouts-prometheus-demo/
├── app/
│   ├── app.py              # Flask app with Prometheus metrics
│   ├── Dockerfile          # Multi-stage Dockerfile
│   └── requirements.txt    # Python dependencies
├── k8s/
│   ├── 01-namespace.yaml           # Namespace
│   ├── 02-analysis-template.yaml   # Prometheus analysis
│   ├── 03-rollout-canary.yaml      # Canary rollout
│   ├── 04-services.yaml            # Services
│   ├── 05-servicemonitor.yaml      # For Prometheus Operator
│   ├── 06-image-versions.yaml      # Image scenarios doc
│   └── 07-load-generator.yaml      # Traffic generator
├── build-images.sh         # Build all image variants
└── README.md
```

## Prerequisites

1. Kubernetes cluster
2. Argo Rollouts installed
3. Prometheus installed

### Install Prometheus (using Helm)

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
kubectl create namespace monitoring
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.service.type=LoadBalancer
```

## Quick Start

### Step 1: Build and Push Images

```bash
cd /Users/raheeskhan/Library/CloudStorage/OneDrive-GeneralCloudComputingCompany/Desktop/devops-class/deployment-strategies/argo-rollouts-prometheus-demo

chmod +x build-images.sh
./build-images.sh
```

Or build individually:

```bash
cd app

# v1-stable (baseline)
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v1 --build-arg ERROR_RATE=0 --build-arg LATENCY=0 \
  -t rahees9983/rollouts-demo-app:v1-stable --push .

# v2-stable (healthy)
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v2 --build-arg ERROR_RATE=0 --build-arg LATENCY=0 \
  -t rahees9983/rollouts-demo-app:v2-stable --push .

# v2-buggy (50% errors)
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v2 --build-arg ERROR_RATE=0.5 --build-arg LATENCY=0 \
  -t rahees9983/rollouts-demo-app:v2-buggy --push .

# v2-slow (2s latency)
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg APP_VERSION=v2 --build-arg ERROR_RATE=0 --build-arg LATENCY=2 \
  -t rahees9983/rollouts-demo-app:v2-slow --push .
```

### Step 2: Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/

# Watch rollout
kubectl argo rollouts get rollout demo-app -n rollouts-demo -w
```

### Step 3: Start Load Generator

```bash
kubectl apply -f k8s/07-load-generator.yaml
```

## Demo Scenarios

### Scenario 1: Successful Deployment ✅

```bash
# Update to stable v2
kubectl argo rollouts set image demo-app \
  app=rahees9983/rollouts-demo-app:v2-stable \
  -n rollouts-demo

# Watch progress
kubectl argo rollouts get rollout demo-app -n rollouts-demo -w
```

**Expected Result:** Analysis passes → Deployment completes

### Scenario 2: Failed Deployment (High Error Rate) ❌

```bash
# Update to buggy version (50% errors)
kubectl argo rollouts set image demo-app \
  app=rahees9983/rollouts-demo-app:v2-buggy \
  -n rollouts-demo

# Watch progress
kubectl argo rollouts get rollout demo-app -n rollouts-demo -w
```

**Expected Result:** Analysis fails → Automatic ROLLBACK to v1

### Scenario 3: Failed Deployment (High Latency) ❌

```bash
# Update to slow version (2s latency)
kubectl argo rollouts set image demo-app \
  app=rahees9983/rollouts-demo-app:v2-slow \
  -n rollouts-demo

# Watch progress
kubectl argo rollouts get rollout demo-app -n rollouts-demo -w
```

**Expected Result:** Latency analysis fails → Automatic ROLLBACK

## Monitoring Commands

```bash
# Watch rollout status
kubectl argo rollouts get rollout demo-app -n rollouts-demo -w

# List analysis runs
kubectl get analysisrun -n rollouts-demo

# Describe failed analysis
kubectl describe analysisrun <name> -n rollouts-demo

# Check Prometheus metrics
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
# Open http://localhost:9090

# View app metrics directly
kubectl port-forward svc/demo-app-stable -n rollouts-demo 8080:80
# Open http://localhost:8080/metrics
```

## Prometheus Queries

```promql
# Success rate
sum(rate(http_requests_total{status="200", namespace="rollouts-demo"}[1m])) /
sum(rate(http_requests_total{namespace="rollouts-demo"}[1m]))

# Error rate
sum(rate(http_errors_total{namespace="rollouts-demo"}[1m])) /
sum(rate(http_requests_total{namespace="rollouts-demo"}[1m]))

# P99 Latency
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{namespace="rollouts-demo"}[1m])) by (le))

# Request count by version
sum by (version) (rate(http_requests_total{namespace="rollouts-demo"}[1m]))
```

## App Endpoints

| Endpoint | Description |
|----------|-------------|
| `/` | Main page with version info |
| `/health` | Health check (always 200) |
| `/ready` | Readiness check |
| `/api/data` | API endpoint (respects error rate) |
| `/metrics` | Prometheus metrics |

## Cleanup

```bash
kubectl delete -f k8s/
```
