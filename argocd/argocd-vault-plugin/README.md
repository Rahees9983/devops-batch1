# HashiCorp Vault + ArgoCD Vault Plugin Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Part 1: HashiCorp Vault Basics](#part-1-hashicorp-vault-basics)
4. [Part 2: Installing Vault on Kubernetes](#part-2-installing-vault-on-kubernetes)
5. [Part 3: Vault Configuration](#part-3-vault-configuration)
6. [Part 4: ArgoCD Vault Plugin Setup](#part-4-argocd-vault-plugin-setup)
7. [Part 5: Using AVP in Applications](#part-5-using-avp-in-applications)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What is HashiCorp Vault?
Vault is a secrets management tool that provides:
- **Secrets Storage**: Securely store and access secrets (passwords, API keys, certificates)
- **Dynamic Secrets**: Generate secrets on-demand (database credentials, cloud credentials)
- **Encryption as a Service**: Encrypt data without storing it
- **Identity-based Access**: Control who can access what secrets

### What is ArgoCD Vault Plugin (AVP)?
AVP is a plugin for ArgoCD that:
- Retrieves secrets from Vault during GitOps sync
- Replaces placeholders in Kubernetes manifests with actual secrets
- Keeps secrets out of Git repositories

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         GitOps Workflow                              │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐
│  Developer   │────▶│  Git Repo    │────▶│        ArgoCD            │
│              │     │  (manifests  │     │  ┌──────────────────┐    │
│              │     │   with       │     │  │ ArgoCD Vault     │    │
│              │     │  placeholders│     │  │ Plugin (AVP)     │    │
│              │     │   <secret>)  │     │  └────────┬─────────┘    │
└──────────────┘     └──────────────┘     └───────────┼──────────────┘
                                                      │
                                                      │ Fetch secrets
                                                      ▼
                                          ┌──────────────────────────┐
                                          │    HashiCorp Vault       │
                                          │  ┌────────────────────┐  │
                                          │  │ Secret Engines     │  │
                                          │  │ - KV (key-value)   │  │
                                          │  │ - Database         │  │
                                          │  │ - AWS/GCP/Azure    │  │
                                          │  └────────────────────┘  │
                                          └──────────────────────────┘
                                                      │
                                                      │ Secrets injected
                                                      ▼
                                          ┌──────────────────────────┐
                                          │   Kubernetes Cluster     │
                                          │  ┌────────────────────┐  │
                                          │  │  Your Application  │  │
                                          │  │  (with real        │  │
                                          │  │   secrets)         │  │
                                          │  └────────────────────┘  │
                                          └──────────────────────────┘
```

---

## Part 1: HashiCorp Vault Basics

### Key Concepts

#### 1. Secrets Engines
Secrets engines are components that store, generate, or encrypt data.

| Engine | Description | Use Case |
|--------|-------------|----------|
| **KV (Key-Value)** | Store static secrets | API keys, passwords |
| **Database** | Generate dynamic DB credentials | MySQL, PostgreSQL, MongoDB |
| **AWS** | Generate dynamic AWS credentials | IAM users, STS tokens |
| **PKI** | Generate X.509 certificates | TLS certificates |
| **Transit** | Encryption as a service | Encrypt/decrypt data |

#### 2. Authentication Methods
How clients prove their identity to Vault.

| Method | Description | Use Case |     
|--------|-------------|----------|
| **Token** | Direct token authentication | Simple/dev setups |
| **Kubernetes** | Use K8s service accounts | Pods in Kubernetes |
| **AppRole** | Machine-to-machine auth | CI/CD, automation |
| **OIDC/JWT** | External identity providers | SSO integration |
| **Userpass** | Username/password | Human users |

#### 3. Policies
Policies define what secrets a client can access.

```hcl
# Example policy
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "database/creds/myapp-role" {
  capabilities = ["read"]
}
```

#### 4. Vault Paths
Secrets are organized in paths like a filesystem:

```
secret/                    # KV secrets engine mount
├── data/                  # KV v2 uses /data/ prefix
│   ├── myapp/
│   │   ├── database      # secret/data/myapp/database
│   │   └── api-keys      # secret/data/myapp/api-keys
│   └── production/
│       └── credentials   # secret/data/production/credentials
```

---

## Part 2: Installing Vault on Kubernetes

### Option 1: Development Mode (Learning)

```bash
# Apply the dev vault manifest
kubectl apply -f 01-vault-dev/

# This creates:
# - Vault in dev mode (unsealed, in-memory storage)
# - Root token: root
# - Good for learning, NOT for production
```

### Option 2: Production Mode with Helm

```bash
# Add HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  -f 02-vault-prod/helm-values.yaml
```

### Accessing Vault UI

```bash
# Port forward to access UI
kubectl port-forward svc/vault 8200:8200 -n vault

# Open browser: http://localhost:8200
# Dev mode token: root
```

---

## Part 3: Vault Configuration

### Step 1: Enable KV Secrets Engine

```bash
# Exec into vault pod
kubectl exec -it vault-0 -n vault -- /bin/sh

# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2

# Or use the API
curl --header "X-Vault-Token: root" \
  --request POST \
  --data '{"type":"kv-v2"}' \
  http://localhost:8200/v1/sys/mounts/secret
```

### Step 2: Create Secrets

```bash
# Create a secret
vault kv put secret/myapp/config \
  username="admin" \
  password="supersecret" \
  api_key="sk-12345"

# Read the secret
vault kv get secret/myapp/config

# List secrets
vault kv list secret/myapp/
```

### Step 3: Enable Kubernetes Auth

```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure it to talk to Kubernetes API
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

### Step 4: Create Policy for ArgoCD

```bash
# Create policy file
vault policy write argocd-policy - <<EOF
path "secret/data/*" {
  capabilities = ["read"]
}
EOF
```

### Step 5: Create Kubernetes Auth Role

```bash
# Create role for ArgoCD
vault write auth/kubernetes/role/argocd \
  bound_service_account_names=argocd-repo-server \
  bound_service_account_namespaces=argocd \
  policies=argocd-policy \
  ttl=1h
```

---

## Part 4: ArgoCD Vault Plugin Setup

### How AVP Works

1. ArgoCD syncs manifests from Git
2. AVP scans for placeholders like `<path:secret/data/myapp/config#password>`
3. AVP authenticates to Vault
4. AVP fetches secrets and replaces placeholders
5. ArgoCD applies the manifests with real values

### Placeholder Syntax

```yaml
# Basic syntax
<path:secret/data/myapp/config#key>

# With specific version
<path:secret/data/myapp/config#key#version=2>

# Examples in a Kubernetes manifest
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
type: Opaque
stringData:
  password: <path:secret/data/myapp/config#password>
  api-key: <path:secret/data/myapp/config#api_key>
```

### Installation Methods

#### Method 1: Sidecar Container (Recommended)

The AVP runs as an init container that processes manifests.

```bash
kubectl apply -f 03-argocd-vault-plugin/
```

#### Method 2: ConfigManagementPlugin v2

Using ArgoCD's plugin system (2.4+).

See `03-argocd-vault-plugin/argocd-cm-plugin.yaml`

---

## Part 5: Using AVP in Applications

### Example 1: Simple Secret

```yaml
# In Git repo (safe to commit)
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
  annotations:
    avp.kubernetes.io/path: "secret/data/myapp/config"
type: Opaque
stringData:
  username: <username>
  password: <password>
```

### Example 2: Inline Placeholders

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  config.yaml: |
    database:
      host: <path:secret/data/myapp/database#host>
      port: <path:secret/data/myapp/database#port>
      username: <path:secret/data/myapp/database#username>
      password: <path:secret/data/myapp/database#password>
```

### Example 3: Deployment with Secrets

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:latest
          env:
            - name: DB_PASSWORD
              value: <path:secret/data/myapp/database#password>
            - name: API_KEY
              value: <path:secret/data/myapp/api#key>
```

### ArgoCD Application with AVP

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/your/repo
    path: apps/myapp
    plugin:
      name: argocd-vault-plugin
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
```

---

## Troubleshooting

### Check Vault Status

```bash
# Check if Vault is running
kubectl get pods -n vault

# Check Vault status
kubectl exec -it vault-0 -n vault -- vault status

# View Vault logs
kubectl logs vault-0 -n vault
```

### Check AVP Logs

```bash
# Check ArgoCD repo-server logs
kubectl logs -n argocd deployment/argocd-repo-server -c avp

# Check for plugin errors
kubectl logs -n argocd deployment/argocd-repo-server | grep -i vault
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `permission denied` | Policy doesn't allow access | Check Vault policy |
| `authentication failed` | Wrong auth method config | Verify K8s auth setup |
| `secret not found` | Wrong path | Check path format (KV v2 needs `/data/`) |
| `plugin not found` | AVP not installed | Check ConfigManagementPlugin |

### Debug Commands

```bash
# Test Vault auth from a pod
kubectl run vault-test --rm -it --image=vault -- /bin/sh
vault login -method=kubernetes role=argocd
vault kv get secret/myapp/config

# Verify service account
kubectl get sa argocd-repo-server -n argocd -o yaml
```

---

## File Structure

```
argocd-vault-plugin/
├── README.md                           # This guide
├── 01-vault-dev/                       # Development Vault setup
│   ├── namespace.yaml
│   ├── vault-deployment.yaml
│   └── vault-service.yaml
├── 02-vault-prod/                      # Production Vault setup
│   ├── helm-values.yaml
│   └── vault-ha-values.yaml
├── 03-argocd-vault-plugin/             # AVP installation
│   ├── argocd-repo-server-patch.yaml
│   ├── argocd-cm-plugin.yaml
│   └── avp-secret.yaml
├── 04-vault-config/                    # Vault configuration
│   ├── policies/
│   │   └── argocd-policy.hcl
│   └── scripts/
│       └── setup-vault.sh
├── 05-examples/                        # Example applications
│   ├── simple-secret/
│   ├── configmap-with-secrets/
│   └── full-app/
└── scripts/
    ├── install-vault-dev.sh
    ├── configure-vault.sh
    └── test-avp.sh
```

---

## Quick Start Commands

```bash
# 1. Install Vault (dev mode)
kubectl apply -f 01-vault-dev/

# 2. Wait for Vault to be ready
kubectl wait --for=condition=ready pod/vault-0 -n vault --timeout=120s

# 3. Configure Vault
./scripts/configure-vault.sh

# 4. Install AVP in ArgoCD
kubectl apply -f 03-argocd-vault-plugin/

# 5. Restart ArgoCD repo-server
kubectl rollout restart deployment argocd-repo-server -n argocd

# 6. Deploy example app
kubectl apply -f 05-examples/simple-secret/application.yaml
```
