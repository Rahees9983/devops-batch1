# Kubernetes Gateway API Guide

Complete guide to understanding and using Gateway API - the next-generation routing API for Kubernetes.

## Table of Contents
- [What is Gateway API?](#what-is-gateway-api)
- [Gateway API vs Ingress](#gateway-api-vs-ingress)
- [Core Resources](#core-resources)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Advanced Features](#advanced-features)
- [Migration from Ingress](#migration-from-ingress)
- [Best Practices](#best-practices)

---

## What is Gateway API?

Gateway API is a collection of Kubernetes APIs that provide dynamic infrastructure provisioning and advanced traffic routing capabilities. It's designed to be:

- **Expressive**: Rich functionality for HTTP, TCP, UDP, and more
- **Extensible**: Policy attachment and custom resources
- **Role-oriented**: Separates infrastructure from routing concerns
- **Portable**: Works across different implementations

**Status**: GA (Generally Available) as of v1.0 for core features

---

## Gateway API vs Ingress

### Comparison Table:

| Aspect | Ingress | Gateway API |
|--------|---------|-------------|
| **Design** | Monolithic | Modular & role-oriented |
| **Protocols** | HTTP/HTTPS only | HTTP, HTTPS, TCP, UDP, gRPC |
| **TLS** | Basic support | Advanced (SNI, multiple certs) |
| **Traffic Splitting** | Annotations (limited) | Native weighted routing |
| **Header Manipulation** | Controller-specific annotations | Built-in filters |
| **Cross-namespace** | No | Yes (with ReferenceGrant) |
| **Extensibility** | Annotations | Policy attachment |
| **Maturity** | Stable (v1) | GA (v1.0 for core) |

### When to Use What?

**Use Ingress when:**
- Simple HTTP/HTTPS routing
- Basic TLS termination
- Single namespace apps
- Existing Ingress setup works fine

**Use Gateway API when:**
- Advanced traffic management (canary, blue-green)
- Multiple protocols (TCP, UDP)
- Header manipulation, URL rewriting
- Cross-namespace routing
- Traffic mirroring/shadowing
- Future-proofing your infrastructure

---

## Core Resources

### 1. GatewayClass

Defines the controller implementation (similar to IngressClass).

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: k8s.io/gateway-nginx
  description: "NGINX Gateway Controller"
```

**Role**: Infrastructure Admin

### 2. Gateway

Defines infrastructure configuration: listeners, ports, protocols, TLS.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: default
spec:
  gatewayClassName: nginx
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: example.com
      tls:
        mode: Terminate
        certificateRefs:
          - name: tls-secret
```

**Role**: Cluster Operator

### 3. HTTPRoute

Defines HTTP routing rules (similar to Ingress rules).

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
  namespace: default
spec:
  parentRefs:
    - name: my-gateway
  hostnames:
    - example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api-service
          port: 8080
```

**Role**: Application Developer

### 4. ReferenceGrant

Allows cross-namespace references.

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-default-namespace
  namespace: production
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: default
  to:
    - group: ""
      kind: Service
```

**Role**: Namespace Owner

---

## Architecture

### Separation of Concerns:

```
┌────────────────────────────────────────────────────────────┐
│                     Gateway API Model                       │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌─────────────┐  │
│  │Infrastructure│    │ Cluster Ops  │    │   App Dev   │  │
│  │    Admin     │    │              │    │             │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬──────┘  │
│         │                   │                    │         │
│         ▼                   ▼                    ▼         │
│  ┌──────────────┐    ┌──────────────┐    ┌─────────────┐  │
│  │ GatewayClass │    │   Gateway    │    │  HTTPRoute  │  │
│  │              │    │              │    │             │  │
│  │ • Controller │    │ • Listeners  │    │ • Hostnames │  │
│  │ • Settings   │    │ • TLS Config │    │ • Rules     │  │
│  │              │    │ • Ports      │    │ • Backends  │  │
│  └──────────────┘    └──────────────┘    └─────────────┘  │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### Request Flow:

```
┌─────────┐
│ Client  │
└────┬────┘
     │ HTTPS Request
     ▼
┌─────────────────┐
│    Gateway      │ ← Configured by: Gateway resource
│  (Listener)     │   • Port 443
│  • TLS Terminate│   • Hostname matching
│  • SNI matching │   • Certificate
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│   HTTPRoute     │ ← Configured by: HTTPRoute resource
│  (Routing)      │   • Path matching
│  • Match rules  │   • Header matching
│  • Filters      │   • Traffic splitting
└────┬────────────┘
     │
     ├─────────┬─────────┐
     ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐
│Service │ │Service │ │Service │
│  80%   │ │  15%   │ │   5%   │
└────────┘ └────────┘ └────────┘
  Stable     Canary      Beta
```

---

## Getting Started

### Step 1: Check Gateway API Installation

```bash
# Check if Gateway API CRDs are installed
kubectl get crd | grep gateway

# You should see:
# gatewayclasses.gateway.networking.k8s.io
# gateways.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
# tcproutes.gateway.networking.k8s.io
# grpcroutes.gateway.networking.k8s.io
# referencegrants.gateway.networking.k8s.io
```

### Step 2: Install Gateway API CRDs (if not present)

```bash
# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# For experimental features
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
```

### Step 3: Install a Gateway Controller

**For NGINX:**
```bash
kubectl apply -f https://github.com/nginxinc/nginx-gateway-fabric/releases/latest/download/nginx-gateway-fabric.yaml
```

**For Istio:**
```bash
istioctl install --set profile=minimal
```

**For Envoy Gateway:**
```bash
kubectl apply -f https://github.com/envoyproxy/gateway/releases/latest/download/quickstart.yaml
```

### Step 4: Create Your First Gateway

```bash
# Apply the gateway configuration
kubectl apply -f gateway-api-example.yaml

# Check Gateway status
kubectl get gateway
kubectl describe gateway saudicloud-gateway

# Check HTTPRoutes
kubectl get httproute
kubectl describe httproute frontend-route
```

### Step 5: Verify

```bash
# Get Gateway external IP
kubectl get gateway saudicloud-gateway -o jsonpath='{.status.addresses[0].value}'

# Test the route
curl -k https://frontend.saudicloud.com
```

---

## Advanced Features

### 1. Traffic Splitting (Canary Deployments)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
spec:
  rules:
    - backendRefs:
        - name: stable-service
          port: 8080
          weight: 90
        - name: canary-service
          port: 8080
          weight: 10
```

**Use Cases:**
- Canary deployments (gradually roll out new versions)
- A/B testing
- Blue-green deployments

### 2. Header-Based Routing

```yaml
rules:
  - matches:
      - headers:
          - name: X-User-Type
            value: premium
    backendRefs:
      - name: premium-service
        port: 8080
```

**Use Cases:**
- User segmentation
- Feature flags
- API versioning

### 3. Request/Response Header Modification

```yaml
filters:
  - type: RequestHeaderModifier
    requestHeaderModifier:
      add:
        - name: X-Custom-Header
          value: my-value
      set:
        - name: X-Env
          value: production
      remove:
        - X-Debug-Header
```

**Use Cases:**
- Add authentication tokens
- Remove sensitive headers
- Set environment indicators

### 4. URL Rewriting

```yaml
filters:
  - type: URLRewrite
    urlRewrite:
      path:
        type: ReplacePrefixMatch
        replacePrefixMatch: /v2
```

**Use Cases:**
- API versioning
- Legacy URL support
- Path normalization

### 5. Request Mirroring (Traffic Shadowing)

```yaml
filters:
  - type: RequestMirror
    requestMirror:
      backendRef:
        name: shadow-service
        port: 8080
```

**Use Cases:**
- Test new versions with real traffic (without affecting users)
- Debugging production issues
- Performance testing

### 6. Timeouts

```yaml
rules:
  - timeouts:
      request: 30s
      backendRequest: 25s
    backendRefs:
      - name: my-service
        port: 8080
```

**Use Cases:**
- Prevent slow requests from blocking resources
- Set different timeouts per route
- Improve reliability

### 7. HTTP to HTTPS Redirect

```yaml
filters:
  - type: RequestRedirect
    requestRedirect:
      scheme: https
      statusCode: 301
```

**Use Cases:**
- Force HTTPS
- Domain redirects
- URL canonicalization

### 8. TCP/UDP Routing

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: database-route
spec:
  parentRefs:
    - name: my-gateway
  rules:
    - backendRefs:
        - name: postgres-service
          port: 5432
```

**Use Cases:**
- Database connections
- Message queues
- Custom TCP/UDP protocols

---

## Migration from Ingress

### Ingress Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - example.com
      secretName: tls-secret
  rules:
    - host: example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
```

### Gateway API Equivalent:

```yaml
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: nginx
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: example.com
      tls:
        mode: Terminate
        certificateRefs:
          - name: tls-secret

---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-route
spec:
  parentRefs:
    - name: my-gateway
  hostnames:
    - example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api-service
          port: 8080
```

### Migration Steps:

1. **Install Gateway API CRDs** (if not present)
2. **Create GatewayClass** (usually provided by your controller)
3. **Create Gateway** (infrastructure config from Ingress)
4. **Create HTTPRoute** (routing rules from Ingress)
5. **Test** side-by-side with existing Ingress
6. **Switch DNS** to Gateway
7. **Remove old Ingress**

---

## Best Practices

### 1. Separate Concerns

```yaml
# Infrastructure team manages Gateway
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: infrastructure

# App teams manage HTTPRoutes
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
  namespace: my-app
spec:
  parentRefs:
    - name: shared-gateway
      namespace: infrastructure
```

### 2. Use ReferenceGrant for Cross-Namespace

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-routes
  namespace: infrastructure
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: my-app
  to:
    - group: gateway.networking.k8s.io
      kind: Gateway
```

### 3. Organize Routes Logically

```yaml
# One HTTPRoute per service
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  labels:
    app: frontend
    team: platform
spec:
  parentRefs:
    - name: my-gateway
  rules:
    - matches:
        - path:
            value: /
      backendRefs:
        - name: frontend-service
          port: 8080
```

### 4. Use Meaningful Names

```yaml
# Good naming
Gateway: prod-external-gateway
HTTPRoute: api-v1-route
Listener: https-api

# Bad naming
Gateway: gateway-1
HTTPRoute: route-1
Listener: listener-1
```

### 5. Monitor and Observe

```bash
# Check Gateway status
kubectl get gateway -A
kubectl describe gateway <name>

# Check HTTPRoute status
kubectl get httproute -A
kubectl describe httproute <name>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### 6. Gradual Rollout

Use traffic splitting for safe deployments:

```yaml
# Week 1: 5% to new version
backendRefs:
  - name: v1-service
    weight: 95
  - name: v2-service
    weight: 5

# Week 2: 25% to new version
# Week 3: 50% to new version
# Week 4: 100% to new version
```

---

## Common Commands

```bash
# List all Gateway API resources
kubectl api-resources | grep gateway.networking.k8s.io

# Get all Gateways
kubectl get gateway -A

# Get all HTTPRoutes
kubectl get httproute -A

# Describe Gateway
kubectl describe gateway <name> -n <namespace>

# Check Gateway status
kubectl get gateway <name> -n <namespace> -o jsonpath='{.status.conditions[*].type}'

# Get Gateway external IP
kubectl get gateway <name> -n <namespace> -o jsonpath='{.status.addresses[0].value}'

# Watch HTTPRoute status
kubectl get httproute -w

# Debug HTTPRoute
kubectl describe httproute <name> -n <namespace>
```

---

## Resources

- **Official Documentation**: https://gateway-api.sigs.k8s.io/
- **GitHub**: https://github.com/kubernetes-sigs/gateway-api
- **API Reference**: https://gateway-api.sigs.k8s.io/api-types/gateway/
- **Implementations**: https://gateway-api.sigs.k8s.io/implementations/

---

## Summary

Gateway API is the future of Kubernetes routing. It provides:

✅ **Better separation of concerns**
✅ **More expressive routing rules**
✅ **Native support for advanced features**
✅ **Portable across implementations**
✅ **Extensible via policies**

Start experimenting with Gateway API today and future-proof your infrastructure!
