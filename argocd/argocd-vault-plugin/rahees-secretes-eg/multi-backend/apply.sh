#!/bin/bash
# Script to apply multi-backend AVP setup

set -e

echo "=== Applying AVP Multi-Backend Setup ==="

# Step 1: Apply secrets
echo "1. Creating secrets..."
kubectl apply -f 1-vault-secret.yaml
kubectl apply -f 2-aws-secret.yaml

# Step 2: Apply ConfigMap with both plugin definitions
echo "2. Creating CMP plugin ConfigMap..."
kubectl apply -f 3-cmp-plugins-configmap.yaml

# Step 3: Patch repo-server with both sidecars
echo "3. Patching argocd-repo-server deployment..."
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
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "cmp-tmp-vault",
      "emptyDir": {}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "cmp-tmp-aws",
      "emptyDir": {}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/-",
    "value": {
      "name": "avp-vault",
      "command": ["/var/run/argocd/argocd-cmp-server"],
      "image": "quay.io/argoproj/argocd:v3.2.2",
      "envFrom": [{"secretRef": {"name": "avp-vault-credentials"}}],
      "securityContext": {"runAsNonRoot": true, "runAsUser": 999},
      "volumeMounts": [
        {"mountPath": "/var/run/argocd", "name": "var-files"},
        {"mountPath": "/home/argocd/cmp-server/plugins", "name": "plugins"},
        {"mountPath": "/tmp", "name": "cmp-tmp-vault"},
        {"mountPath": "/home/argocd/cmp-server/config/plugin.yaml", "subPath": "avp-vault.yaml", "name": "cmp-plugin"},
        {"mountPath": "/usr/local/bin/argocd-vault-plugin", "name": "custom-tools", "subPath": "argocd-vault-plugin"}
      ]
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/-",
    "value": {
      "name": "avp-aws",
      "command": ["/var/run/argocd/argocd-cmp-server"],
      "image": "quay.io/argoproj/argocd:v3.2.2",
      "envFrom": [{"secretRef": {"name": "avp-aws-credentials"}}],
      "securityContext": {"runAsNonRoot": true, "runAsUser": 999},
      "volumeMounts": [
        {"mountPath": "/var/run/argocd", "name": "var-files"},
        {"mountPath": "/home/argocd/cmp-server/plugins", "name": "plugins"},
        {"mountPath": "/tmp", "name": "cmp-tmp-aws"},
        {"mountPath": "/home/argocd/cmp-server/config/plugin.yaml", "subPath": "avp-aws.yaml", "name": "cmp-plugin"},
        {"mountPath": "/usr/local/bin/argocd-vault-plugin", "name": "custom-tools", "subPath": "argocd-vault-plugin"}
      ]
    }
  }
]'

# Step 4: Wait for rollout
echo "4. Waiting for rollout..."
kubectl rollout status deployment argocd-repo-server -n argocd

# Step 5: Verify
echo "5. Verifying pod has 3 containers (repo-server + 2 sidecars)..."
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server

echo ""
echo "=== Setup Complete ==="
echo "Available plugins:"
echo "  - argocd-vault-plugin     (for HashiCorp Vault)"
echo "  - argocd-vault-plugin-aws (for AWS Secrets Manager)"
