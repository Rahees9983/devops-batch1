#!/bin/bash

# ============================================================
# Configure Vault for ArgoCD Vault Plugin
# ============================================================
# This script:
# 1. Enables KV v2 secrets engine
# 2. Creates sample secrets
# 3. Enables Kubernetes auth
# 4. Creates policy for ArgoCD
# 5. Creates role for ArgoCD repo-server
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
VAULT_NAMESPACE="${VAULT_NAMESPACE:-vault}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_SA="${ARGOCD_SA:-argocd-repo-server}"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}     Configuring Vault for ArgoCD Vault Plugin${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Check if vault pod is running
if ! kubectl get pod -l app.kubernetes.io/name=vault -n $VAULT_NAMESPACE -o name | grep -q pod; then
    echo -e "${RED}Error: Vault pod not found. Please install Vault first.${NC}"
    exit 1
fi

VAULT_POD=$(kubectl get pod -l app.kubernetes.io/name=vault -n $VAULT_NAMESPACE -o jsonpath='{.items[0].metadata.name}')
echo -e "${YELLOW}Using Vault pod: $VAULT_POD${NC}"

# Function to run vault commands
vault_exec() {
    kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- env VAULT_TOKEN=$VAULT_TOKEN vault "$@"
}

# Step 1: Enable KV v2 secrets engine
echo ""
echo -e "${YELLOW}Step 1: Enabling KV v2 secrets engine...${NC}"
vault_exec secrets enable -path=secret kv-v2 2>/dev/null || echo "  (already enabled)"
echo -e "${GREEN}✓ KV v2 secrets engine enabled at 'secret/'${NC}"

# Step 2: Create sample secrets
echo ""
echo -e "${YELLOW}Step 2: Creating sample secrets...${NC}"

# MyApp config
vault_exec kv put secret/myapp/config \
    username="admin" \
    password="supersecret123" \
    api_key="sk-myapp-12345" \
    jwt_secret="jwt-secret-key-here"
echo -e "${GREEN}  ✓ secret/myapp/config${NC}"

# MyApp database
vault_exec kv put secret/myapp/database \
    host="mysql.example.com" \
    port="3306" \
    username="dbuser" \
    password="dbpassword123" \
    dbname="myappdb"
echo -e "${GREEN}  ✓ secret/myapp/database${NC}"

# MyApp API
vault_exec kv put secret/myapp/api \
    key="api-key-12345" \
    secret="api-secret-67890"
echo -e "${GREEN}  ✓ secret/myapp/api${NC}"

# MyApp Redis
vault_exec kv put secret/myapp/redis \
    host="redis.example.com" \
    port="6379" \
    password="redispassword"
echo -e "${GREEN}  ✓ secret/myapp/redis${NC}"

# Demo app secrets
vault_exec kv put secret/demo-app/config \
    db_password="demo-db-pass" \
    api_key="demo-api-key" \
    jwt_secret="demo-jwt-secret"
echo -e "${GREEN}  ✓ secret/demo-app/config${NC}"

vault_exec kv put secret/demo-app/database \
    host="postgres.demo.svc" \
    port="5432" \
    name="demodb" \
    user="demouser" \
    password="demopassword"
echo -e "${GREEN}  ✓ secret/demo-app/database${NC}"

vault_exec kv put secret/demo-app/redis \
    host="redis.demo.svc" \
    password="redis-demo-pass"
echo -e "${GREEN}  ✓ secret/demo-app/redis${NC}"

vault_exec kv put secret/demo-app/docker \
    username="dockeruser" \
    password="dockerpass" \
    auth="ZG9ja2VydXNlcjpkb2NrZXJwYXNz"
echo -e "${GREEN}  ✓ secret/demo-app/docker${NC}"

vault_exec kv put secret/demo-app/payment \
    api_key="pay-key-123" \
    api_secret="pay-secret-456"
echo -e "${GREEN}  ✓ secret/demo-app/payment${NC}"

vault_exec kv put secret/demo-app/email \
    username="email@example.com" \
    password="emailpassword"
echo -e "${GREEN}  ✓ secret/demo-app/email${NC}"

# Step 3: Enable Kubernetes auth
echo ""
echo -e "${YELLOW}Step 3: Enabling Kubernetes authentication...${NC}"
vault_exec auth enable kubernetes 2>/dev/null || echo "  (already enabled)"
echo -e "${GREEN}✓ Kubernetes auth enabled${NC}"

# Step 4: Configure Kubernetes auth
echo ""
echo -e "${YELLOW}Step 4: Configuring Kubernetes auth...${NC}"

# Get Kubernetes API server address
K8S_HOST="https://kubernetes.default.svc"

vault_exec write auth/kubernetes/config \
    kubernetes_host="$K8S_HOST"
echo -e "${GREEN}✓ Kubernetes auth configured${NC}"

# Step 5: Create policy for ArgoCD
echo ""
echo -e "${YELLOW}Step 5: Creating ArgoCD policy...${NC}"
kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- env VAULT_TOKEN=$VAULT_TOKEN sh -c '
vault policy write argocd - <<EOF
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOF
'
echo -e "${GREEN}✓ ArgoCD policy created${NC}"

# Step 6: Create role for ArgoCD
echo ""
echo -e "${YELLOW}Step 6: Creating Kubernetes auth role for ArgoCD...${NC}"
vault_exec write auth/kubernetes/role/argocd \
    bound_service_account_names=$ARGOCD_SA \
    bound_service_account_namespaces=$ARGOCD_NAMESPACE \
    policies=argocd \
    ttl=1h
echo -e "${GREEN}✓ ArgoCD role created${NC}"

# Summary
echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}     Vault Configuration Complete!${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}Created Secrets:${NC}"
echo "  - secret/myapp/config"
echo "  - secret/myapp/database"
echo "  - secret/myapp/api"
echo "  - secret/myapp/redis"
echo "  - secret/demo-app/* (config, database, redis, docker, payment, email)"
echo ""
echo -e "${YELLOW}Kubernetes Auth:${NC}"
echo "  - Role: argocd"
echo "  - Service Account: $ARGOCD_SA"
echo "  - Namespace: $ARGOCD_NAMESPACE"
echo ""
echo -e "${YELLOW}Test Commands:${NC}"
echo "  # List secrets"
echo "  kubectl exec -n vault $VAULT_POD -- env VAULT_TOKEN=root vault kv list secret/"
echo ""
echo "  # Read a secret"
echo "  kubectl exec -n vault $VAULT_POD -- env VAULT_TOKEN=root vault kv get secret/myapp/config"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Apply AVP to ArgoCD: kubectl apply -k ../03-argocd-vault-plugin/"
echo "  2. Restart ArgoCD repo-server: kubectl rollout restart deployment argocd-repo-server -n argocd"
echo "  3. Deploy example app: kubectl apply -f ../05-examples/simple-secret/application.yaml"
