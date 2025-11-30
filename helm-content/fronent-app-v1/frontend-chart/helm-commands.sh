#!/bin/bash

# Helm Template Commands Reference
# This file contains useful Helm template and management commands

CHART_PATH="./frontend-chart"
RELEASE_NAME="frontend"
NAMESPACE="default"

echo "=========================================="
echo "Helm Chart Template & Management Commands"
echo "=========================================="
echo ""

# 1. TEMPLATE RENDERING COMMANDS
echo "1. TEMPLATE RENDERING COMMANDS"
echo "----------------------------"
echo ""

echo "# Render all templates (basic)"
echo "helm template $RELEASE_NAME $CHART_PATH"
echo ""

echo "# Render templates with custom values"
echo "helm template $RELEASE_NAME $CHART_PATH --set replicaCount=3"
echo ""

echo "# Render templates with values file"
echo "helm template $RELEASE_NAME $CHART_PATH -f custom-values.yaml"
echo ""

echo "# Render templates with namespace"
echo "helm template $RELEASE_NAME $CHART_PATH --namespace dev"
echo ""

echo "# Render and save output to file"
echo "helm template $RELEASE_NAME $CHART_PATH > rendered-manifests.yaml"
echo ""

echo "# Render specific template only"
echo "helm template $RELEASE_NAME $CHART_PATH -s templates/deployment.yaml"
echo ""

echo "# Show only the deployment template"
echo "helm template $RELEASE_NAME $CHART_PATH -s templates/deployment.yaml"
echo ""

echo "# Debug mode - shows values and computed templates"
echo "helm template $RELEASE_NAME $CHART_PATH --debug"
echo ""

# 2. VALIDATION & TESTING COMMANDS
echo "2. VALIDATION & TESTING COMMANDS"
echo "--------------------------------"
echo ""

echo "# Lint the chart (check for errors)"
echo "helm lint $CHART_PATH"
echo ""

echo "# Lint with custom values"
echo "helm lint $CHART_PATH --values custom-values.yaml"
echo ""

echo "# Strict linting"
echo "helm lint $CHART_PATH --strict"
echo ""

echo "# Dry-run installation (validates against Kubernetes)"
echo "helm install $RELEASE_NAME $CHART_PATH --dry-run"
echo ""

echo "# Dry-run with debug output"
echo "helm install $RELEASE_NAME $CHART_PATH --dry-run --debug"
echo ""

echo "# Dry-run with custom namespace"
echo "helm install $RELEASE_NAME $CHART_PATH --dry-run --namespace dev --create-namespace"
echo ""

# 3. INSTALLATION COMMANDS
echo "3. INSTALLATION COMMANDS"
echo "------------------------"
echo ""

echo "# Install chart"
echo "helm install $RELEASE_NAME $CHART_PATH"
echo ""

echo "# Install with custom values"
echo "helm install $RELEASE_NAME $CHART_PATH --set replicaCount=3,image.tag=v2"
echo ""

echo "# Install with values file"
echo "helm install $RELEASE_NAME $CHART_PATH -f production-values.yaml"
echo ""

echo "# Install in specific namespace"
echo "helm install $RELEASE_NAME $CHART_PATH --namespace production --create-namespace"
echo ""

echo "# Install and wait for resources to be ready"
echo "helm install $RELEASE_NAME $CHART_PATH --wait --timeout 5m"
echo ""

# 4. UPGRADE COMMANDS
echo "4. UPGRADE COMMANDS"
echo "-------------------"
echo ""

echo "# Upgrade release"
echo "helm upgrade $RELEASE_NAME $CHART_PATH"
echo ""

echo "# Upgrade with new values"
echo "helm upgrade $RELEASE_NAME $CHART_PATH --set image.tag=v2"
echo ""

echo "# Upgrade or install if not exists"
echo "helm upgrade --install $RELEASE_NAME $CHART_PATH"
echo ""

echo "# Upgrade with dry-run"
echo "helm upgrade $RELEASE_NAME $CHART_PATH --dry-run --debug"
echo ""

# 5. INSPECT & INFORMATION COMMANDS
echo "5. INSPECT & INFORMATION COMMANDS"
echo "---------------------------------"
echo ""

echo "# Show chart information"
echo "helm show chart $CHART_PATH"
echo ""

echo "# Show default values"
echo "helm show values $CHART_PATH"
echo ""

echo "# Show all chart information"
echo "helm show all $CHART_PATH"
echo ""

echo "# Show README"
echo "helm show readme $CHART_PATH"
echo ""

echo "# Get computed values for installed release"
echo "helm get values $RELEASE_NAME"
echo ""

echo "# Get all computed values (including defaults)"
echo "helm get values $RELEASE_NAME --all"
echo ""

echo "# Get manifest of installed release"
echo "helm get manifest $RELEASE_NAME"
echo ""

echo "# Get hooks"
echo "helm get hooks $RELEASE_NAME"
echo ""

# 6. RELEASE MANAGEMENT COMMANDS
echo "6. RELEASE MANAGEMENT COMMANDS"
echo "------------------------------"
echo ""

echo "# List all releases"
echo "helm list"
echo ""

echo "# List releases in all namespaces"
echo "helm list --all-namespaces"
echo ""

echo "# Get release status"
echo "helm status $RELEASE_NAME"
echo ""

echo "# Get release history"
echo "helm history $RELEASE_NAME"
echo ""

echo "# Rollback to previous version"
echo "helm rollback $RELEASE_NAME"
echo ""

echo "# Rollback to specific revision"
echo "helm rollback $RELEASE_NAME 2"
echo ""

echo "# Uninstall release"
echo "helm uninstall $RELEASE_NAME"
echo ""

echo "# Uninstall and keep history"
echo "helm uninstall $RELEASE_NAME --keep-history"
echo ""

# 7. PACKAGE COMMANDS
echo "7. PACKAGE COMMANDS"
echo "-------------------"
echo ""

echo "# Package chart into archive"
echo "helm package $CHART_PATH"
echo ""

echo "# Package with specific destination"
echo "helm package $CHART_PATH --destination ./packages"
echo ""

echo "# Package and sign"
echo "helm package $CHART_PATH --sign --key mykey --keyring ~/.gnupg/secring.gpg"
echo ""

# 8. ADVANCED TEMPLATE COMMANDS
echo "8. ADVANCED TEMPLATE COMMANDS"
echo "-----------------------------"
echo ""

echo "# Render with multiple values files (priority: right to left)"
echo "helm template $RELEASE_NAME $CHART_PATH -f values.yaml -f override-values.yaml"
echo ""

echo "# Set multiple values"
echo "helm template $RELEASE_NAME $CHART_PATH \\"
echo "  --set replicaCount=3 \\"
echo "  --set image.tag=v2 \\"
echo "  --set service.nodePort=30081"
echo ""

echo "# Set array values"
echo "helm template $RELEASE_NAME $CHART_PATH \\"
echo "  --set 'podLabels.env=prod,podLabels.team=devops'"
echo ""

echo "# Template with release and chart info"
echo "helm template $RELEASE_NAME $CHART_PATH \\"
echo "  --namespace production \\"
echo "  --create-namespace \\"
echo "  --debug"
echo ""

echo "# Validate templates with kubeval (if installed)"
echo "helm template $RELEASE_NAME $CHART_PATH | kubeval"
echo ""

echo "# Validate templates with kubectl dry-run"
echo "helm template $RELEASE_NAME $CHART_PATH | kubectl apply --dry-run=client -f -"
echo ""

# 9. USEFUL COMBINATIONS
echo "9. USEFUL COMBINATIONS"
echo "----------------------"
echo ""

echo "# Full validation pipeline"
echo "helm lint $CHART_PATH && \\"
echo "helm template $RELEASE_NAME $CHART_PATH --debug && \\"
echo "helm install $RELEASE_NAME $CHART_PATH --dry-run"
echo ""

echo "# Deploy with validation"
echo "helm upgrade --install $RELEASE_NAME $CHART_PATH \\"
echo "  --namespace production \\"
echo "  --create-namespace \\"
echo "  --wait \\"
echo "  --timeout 5m \\"
echo "  --atomic"
echo ""

echo "# Compare current vs new values"
echo "helm get values $RELEASE_NAME > current-values.yaml"
echo "helm template $RELEASE_NAME $CHART_PATH -f new-values.yaml --debug"
echo ""

echo "=========================================="
echo "End of Helm Commands Reference"
echo "=========================================="
