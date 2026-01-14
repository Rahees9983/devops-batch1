#!/bin/bash

# ============================================================
# Test ArgoCD Vault Plugin Setup
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}     Testing ArgoCD Vault Plugin Setup${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

VAULT_NAMESPACE="${VAULT_NAMESPACE:-vault}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

# Test 1: Check Vault is running
echo -e "${YELLOW}Test 1: Checking Vault status...${NC}"
if kubectl get pod -l app.kubernetes.io/name=vault -n $VAULT_NAMESPACE -o jsonpath='{.items[0].status.phase}' | grep -q Running; then
    echo -e "${GREEN}✓ Vault is running${NC}"
else
    echo -e "${RED}✗ Vault is not running${NC}"
    exit 1
fi

# Test 2: Check Vault is unsealed
echo ""
echo -e "${YELLOW}Test 2: Checking Vault seal status...${NC}"
VAULT_POD=$(kubectl get pod -l app.kubernetes.io/name=vault -n $VAULT_NAMESPACE -o jsonpath='{.items[0].metadata.name}')
SEALED=$(kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- vault status -format=json | grep -o '"sealed":[^,]*' | cut -d':' -f2)
if [ "$SEALED" = "false" ]; then
    echo -e "${GREEN}✓ Vault is unsealed${NC}"
else
    echo -e "${RED}✗ Vault is sealed${NC}"
    exit 1
fi

# Test 3: Check secrets exist
echo ""
echo -e "${YELLOW}Test 3: Checking secrets exist...${NC}"
if kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- env VAULT_TOKEN=root vault kv get secret/myapp/config > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Sample secrets exist${NC}"
else
    echo -e "${RED}✗ Sample secrets not found. Run ./configure-vault.sh first${NC}"
    exit 1
fi

# Test 4: Check Kubernetes auth is enabled
echo ""
echo -e "${YELLOW}Test 4: Checking Kubernetes auth...${NC}"
if kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- env VAULT_TOKEN=root vault auth list | grep -q kubernetes; then
    echo -e "${GREEN}✓ Kubernetes auth is enabled${NC}"
else
    echo -e "${RED}✗ Kubernetes auth not enabled${NC}"
    exit 1
fi

# Test 5: Check ArgoCD role exists
echo ""
echo -e "${YELLOW}Test 5: Checking ArgoCD role...${NC}"
if kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- env VAULT_TOKEN=root vault read auth/kubernetes/role/argocd > /dev/null 2>&1; then
    echo -e "${GREEN}✓ ArgoCD role exists${NC}"
else
    echo -e "${RED}✗ ArgoCD role not found${NC}"
    exit 1
fi

# Test 6: Check ArgoCD repo-server has AVP containers
echo ""
echo -e "${YELLOW}Test 6: Checking ArgoCD repo-server AVP containers...${NC}"
if kubectl get deployment argocd-repo-server -n $ARGOCD_NAMESPACE -o jsonpath='{.spec.template.spec.containers[*].name}' | grep -q avp; then
    echo -e "${GREEN}✓ AVP sidecar containers found${NC}"
else
    echo -e "${YELLOW}⚠ AVP sidecar containers not found. Apply AVP patch to ArgoCD.${NC}"
fi

# Test 7: Check AVP credentials secret
echo ""
echo -e "${YELLOW}Test 7: Checking AVP credentials secret...${NC}"
if kubectl get secret argocd-vault-plugin-credentials -n $ARGOCD_NAMESPACE > /dev/null 2>&1; then
    echo -e "${GREEN}✓ AVP credentials secret exists${NC}"
else
    echo -e "${YELLOW}⚠ AVP credentials secret not found${NC}"
fi

# Test 8: Check CMP ConfigMap
echo ""
echo -e "${YELLOW}Test 8: Checking CMP plugin ConfigMap...${NC}"
if kubectl get configmap cmp-plugin -n $ARGOCD_NAMESPACE > /dev/null 2>&1; then
    echo -e "${GREEN}✓ CMP plugin ConfigMap exists${NC}"
else
    echo -e "${YELLOW}⚠ CMP plugin ConfigMap not found${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}     Test Summary${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

echo -e "${YELLOW}Manual verification:${NC}"
echo "  1. Test secret retrieval from Vault:"
echo "     kubectl exec -n vault $VAULT_POD -- env VAULT_TOKEN=root vault kv get secret/myapp/config"
echo ""
echo "  2. Check ArgoCD repo-server logs:"
echo "     kubectl logs deployment/argocd-repo-server -n argocd -c avp"
echo ""
echo "  3. Create a test application:"
echo "     kubectl apply -f ../05-examples/simple-secret/application.yaml"
echo ""
echo "  4. Check if secrets are properly injected:"
echo "     kubectl get secret myapp-secret -n default -o yaml"
