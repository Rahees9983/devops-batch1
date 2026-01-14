# ArgoCD Vault Plugin with AWS Secrets Manager

## Quick Start Steps

### 1. Create secret in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
  --name myapp/prod/credentials \
  --secret-string '{"username":"admin","password":"supersecret123","api_key":"sk-xxxx"}'
```

### 2. Apply Kubernetes resources

```bash
# Apply in order:
kubectl apply -f 1-avp-aws-secret.yaml        # AVP credentials
kubectl apply -f 2-cmp-plugin-configmap.yaml  # Plugin config

# Patch the repo-server deployment (copy command from 3-repo-server-patch.yaml)
kubectl patch deployment argocd-repo-server -n argocd --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "cmp-plugin",
      "configMap": {"name": "cmp-plugin"}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/-",
    "value": {
      "name": "avp",
      "command": ["/var/run/argocd/argocd-cmp-server"],
      "image": "quay.io/argoproj/argocd:v3.2.2",
      "envFrom": [{"secretRef": {"name": "argocd-vault-plugin-credentials"}}],
      "securityContext": {"runAsNonRoot": true, "runAsUser": 999},
      "volumeMounts": [
        {"mountPath": "/var/run/argocd", "name": "var-files"},
        {"mountPath": "/home/argocd/cmp-server/plugins", "name": "plugins"},
        {"mountPath": "/tmp", "name": "tmp"},
        {"mountPath": "/home/argocd/cmp-server/config/plugin.yaml", "subPath": "avp.yaml", "name": "cmp-plugin"},
        {"mountPath": "/usr/local/bin/argocd-vault-plugin", "name": "custom-tools", "subPath": "argocd-vault-plugin"}
      ]
    }
  }
]'
```

### 3. Verify repo-server has 2 containers

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server
# Should show 2/2 READY
```

### 4. Create your Application

```bash
kubectl apply -f 5-argocd-application.yaml
```

## Placeholder Syntax

| Syntax | Example | Description |
|--------|---------|-------------|
| Annotation + placeholder | `<username>` | Use with `avp.kubernetes.io/path` annotation |
| Inline path | `<path:secret-name#key>` | Full path inline |
| With version | `<path:secret-name#key#AWSCURRENT>` | Specific version |
| Full ARN | `<path:arn:aws:secretsmanager:region:account:secret:name#key>` | Cross-account |

## Authentication Options

### Option 1: AWS Access Keys (Simple, not for production)
Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in the secret.

### Option 2: IRSA (Recommended for EKS)
See `6-irsa-setup.yaml` for instructions.

### Option 3: EC2 Instance Profile
If ArgoCD runs on EC2 with an instance profile that has Secrets Manager access, no credentials needed.

## Files Overview

| File | Purpose |
|------|---------|
| `1-avp-aws-secret.yaml` | AVP credentials (AWS keys or just config for IRSA) |
| `2-cmp-plugin-configmap.yaml` | CMP plugin definition |
| `3-repo-server-patch.yaml` | Sidecar container config |
| `4-example-secret.yaml` | Example K8s secrets with placeholders |
| `5-argocd-application.yaml` | ArgoCD Application example |
| `6-irsa-setup.yaml` | IRSA setup instructions |
