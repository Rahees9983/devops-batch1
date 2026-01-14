#!/bin/bash

# ============================================================
# Install Vault in Development Mode
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Installing Vault in Development Mode...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Apply Vault manifests
echo -e "${YELLOW}Creating Vault namespace and resources...${NC}"
kubectl apply -f "$BASE_DIR/01-vault-dev/namespace.yaml"
kubectl apply -f "$BASE_DIR/01-vault-dev/vault-deployment.yaml"
kubectl apply -f "$BASE_DIR/01-vault-dev/vault-service.yaml"

# Wait for Vault to be ready
echo -e "${YELLOW}Waiting for Vault to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=120s

echo -e "${GREEN}✓ Vault installed successfully!${NC}"
echo ""
echo -e "${YELLOW}Vault Details:${NC}"
echo "  Namespace: vault"
echo "  Service: vault.vault.svc.cluster.local:8200"
echo "  Root Token: root"
echo ""
echo -e "${YELLOW}Access Vault UI:${NC}"
echo "  kubectl port-forward svc/vault 8200:8200 -n vault"
echo "  Open: http://localhost:8200"
echo "  Token: root"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Run ./configure-vault.sh to set up secrets and auth"
echo "  2. Apply AVP configuration to ArgoCD"
