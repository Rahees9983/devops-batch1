#!/bin/bash

# ============================================================
# Cleanup Script - Remove Vault and AVP Resources
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}This will remove:${NC}"
echo "  - Vault namespace and all resources"
echo "  - AVP configuration from ArgoCD"
echo "  - Example applications"
echo ""
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${YELLOW}Removing example applications...${NC}"
kubectl delete -f "$BASE_DIR/05-examples/simple-secret/application.yaml" --ignore-not-found 2>/dev/null || true
kubectl delete -f "$BASE_DIR/05-examples/full-app/application.yaml" --ignore-not-found 2>/dev/null || true

echo ""
echo -e "${YELLOW}Removing AVP configuration from ArgoCD...${NC}"
kubectl delete secret argocd-vault-plugin-credentials -n argocd --ignore-not-found 2>/dev/null || true
kubectl delete secret argocd-vault-plugin-credentials-dev -n argocd --ignore-not-found 2>/dev/null || true
kubectl delete configmap cmp-plugin -n argocd --ignore-not-found 2>/dev/null || true

echo ""
echo -e "${YELLOW}Removing Vault...${NC}"
kubectl delete -f "$BASE_DIR/01-vault-dev/" --ignore-not-found 2>/dev/null || true

echo ""
echo -e "${YELLOW}Removing demo-app namespace...${NC}"
kubectl delete namespace demo-app --ignore-not-found 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
echo -e "${YELLOW}Note: You may need to restart ArgoCD repo-server to remove AVP sidecars:${NC}"
echo "  kubectl rollout restart deployment argocd-repo-server -n argocd"
