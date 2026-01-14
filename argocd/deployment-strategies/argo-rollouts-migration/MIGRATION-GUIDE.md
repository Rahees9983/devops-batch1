# Deployment to Argo Rollout Migration Guide

## POC Overview

This POC demonstrates how to convert an existing Kubernetes Deployment to Argo Rollout.

## Files

| File | Description |
|------|-------------|
| 01-original-deployment.yaml | Original K8s Deployment (before migration) |
| 02-converted-rollout.yaml | Converted to Rollout with Blue-Green strategy |
| 03-converted-rollout-canary.yaml | Converted to Rollout with Canary strategy |

## Step-by-Step Migration

### Step 1: Install Argo Rollouts (if not already installed)

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Install kubectl plugin
brew install argoproj/tap/kubectl-argo-rollouts
# OR for Linux:
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

### Step 2: Deploy Original Deployment (simulate existing app)

```bash
kubectl apply -f 01-original-deployment.yaml

# Verify
kubectl get deployment myapp
kubectl get pods -l app=myapp
kubectl get svc myapp-svc
```

### Step 3: Delete Existing Deployment (prepare for migration)

```bash
# Scale down first to avoid conflicts
kubectl scale deployment myapp --replicas=0

# Delete the deployment (pods will be recreated by Rollout)
kubectl delete deployment myapp

# Keep the service or delete if changing to active/preview pattern
kubectl delete svc myapp-svc
```

### Step 4: Apply Converted Rollout

```bash
kubectl apply -f 02-converted-rollout.yaml

# Verify rollout created
kubectl get rollouts
kubectl argo rollouts get rollout myapp

# Check pods
kubectl get pods -l app=myapp

# Check services
kubectl get svc myapp-active myapp-preview
```

### Step 5: Test Blue-Green Deployment

```bash
# Get service IPs
kubectl get svc myapp-active myapp-preview

# Test active service (v1)
curl http://<ACTIVE-IP>

# Update to v2
kubectl argo rollouts set image myapp app=rahees9983/deployment-strategy-app:v2

# Watch the rollout
kubectl argo rollouts get rollout myapp -w

# Test preview service (v2)
curl http://<PREVIEW-IP>

# Promote when ready
kubectl argo rollouts promote myapp

# Or abort if something is wrong
kubectl argo rollouts abort myapp
```

## Key Differences: Deployment vs Rollout

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT                                    │
├─────────────────────────────────────────────────────────────────┤
│  apiVersion: apps/v1                                            │
│  kind: Deployment                                               │
│  spec:                                                          │
│    replicas: 3                                                  │
│    selector: ...                                                │
│    template: ...                                                │
│    strategy:                     ← Only RollingUpdate or        │
│      type: RollingUpdate           Recreate available           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    ROLLOUT                                       │
├─────────────────────────────────────────────────────────────────┤
│  apiVersion: argoproj.io/v1alpha1    ← Changed                  │
│  kind: Rollout                        ← Changed                  │
│  spec:                                                          │
│    replicas: 3                                                  │
│    selector: ...                                                │
│    template: ...                                                │
│    strategy:                                                    │
│      blueGreen:                  ← Blue-Green strategy          │
│        activeService: ...                                       │
│        previewService: ...                                      │
│      # OR                                                       │
│      canary:                     ← Canary strategy              │
│        steps: ...                                               │
└─────────────────────────────────────────────────────────────────┘
```

## Migration Checklist

- [ ] Argo Rollouts controller installed
- [ ] kubectl argo rollouts plugin installed
- [ ] Backup existing Deployment YAML
- [ ] Scale down existing Deployment
- [ ] Delete existing Deployment
- [ ] Create preview service (for blue-green)
- [ ] Rename existing service to active (for blue-green)
- [ ] Apply new Rollout
- [ ] Verify pods are running
- [ ] Test active and preview services
- [ ] Test image update and promotion flow

## Rollback

If migration fails, revert to original deployment:

```bash
# Delete rollout and services
kubectl delete rollout myapp
kubectl delete svc myapp-active myapp-preview

# Re-apply original deployment
kubectl apply -f 01-original-deployment.yaml
```

## Common Commands

```bash
# Check rollout status
kubectl argo rollouts get rollout myapp

# Watch rollout
kubectl argo rollouts get rollout myapp -w

# Update image
kubectl argo rollouts set image myapp app=<new-image>

# Promote (blue-green: switch traffic, canary: next step)
kubectl argo rollouts promote myapp

# Abort rollout
kubectl argo rollouts abort myapp

# Retry aborted rollout
kubectl argo rollouts retry rollout myapp

# Undo to previous version
kubectl argo rollouts undo myapp

# List all rollouts
kubectl get rollouts

# Dashboard (opens in browser)
kubectl argo rollouts dashboard
```
