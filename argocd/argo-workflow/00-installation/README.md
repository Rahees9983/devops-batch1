# Argo Workflows Installation Guide

## Prerequisites

- Kubernetes cluster (EKS, GKE, AKS, or local like minikube/kind)
- kubectl configured
- Helm (optional)

---

## Method 1: Quick Install (Recommended for Learning)

```bash
# Create namespace
kubectl create namespace argo

# Install Argo Workflows (latest stable)
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.5/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=Ready pods --all -n argo --timeout=300s

# Verify installation
kubectl get pods -n argo
```

---

## Method 2: Using Helm

```bash
# Add Argo Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install with Helm
helm install argo-workflows argo/argo-workflows \
  --namespace argo \
  --create-namespace \
  --set server.serviceType=LoadBalancer
```

---

## Method 3: Using Local Files

```bash
# Apply the install.yaml from this directory
kubectl apply -n argo -f install.yaml
```

---

## Install Argo CLI

### Mac
```bash
brew install argo
```

### Linux
```bash
curl -sLO https://github.com/argoproj/argo-workflows/releases/download/v3.5.5/argo-linux-amd64.gz
gunzip argo-linux-amd64.gz
chmod +x argo-linux-amd64
sudo mv argo-linux-amd64 /usr/local/bin/argo
```

### Verify CLI
```bash
argo version
```

---

## Access Argo UI

### Option 1: Port Forward (Quick)
```bash
kubectl -n argo port-forward svc/argo-server 2746:2746
# Open: https://localhost:2746
```

### Option 2: LoadBalancer (Cloud)
```bash
kubectl patch svc argo-server -n argo -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argo-server -n argo
```

### Option 3: Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argo-server-ingress
  namespace: argo
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
    - host: argo.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argo-server
                port:
                  number: 2746
```

---

## Configure Authentication (Optional)

By default, Argo uses `server` auth mode. For production:

```bash
# Patch to use client auth
kubectl patch deployment argo-server -n argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["server", "--auth-mode=client"]}]'
```

---

## Configure ServiceAccount for Workflows

```bash
# Apply the workflow-sa.yaml
kubectl apply -f workflow-sa.yaml
```

---

## Verify Installation

```bash
# Check all pods are running
kubectl get pods -n argo

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# argo-server-xxx                        1/1     Running   0          2m
# workflow-controller-xxx                1/1     Running   0          2m

# Submit a test workflow
argo submit -n argo --watch https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml

# Check workflows
argo list -n argo
```

---

## Troubleshooting

### Pods stuck in Pending
```bash
kubectl describe pod <pod-name> -n argo
# Check for resource issues or image pull errors
```

### Workflow stuck in Pending
```bash
# Check workflow controller logs
kubectl logs -n argo deployment/workflow-controller

# Check if ServiceAccount has permissions
kubectl auth can-i create pods --as=system:serviceaccount:argo:argo-workflow -n argo
```

### UI not accessible
```bash
# Check argo-server logs
kubectl logs -n argo deployment/argo-server

# Check service
kubectl get svc -n argo
```

---

## Next Steps

After installation is complete, proceed to `../01-basics/` to create your first workflow!
