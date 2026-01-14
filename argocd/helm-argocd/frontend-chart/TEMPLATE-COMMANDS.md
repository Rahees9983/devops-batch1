# Helm Template Commands - Quick Reference

## Most Common Template Commands

### 1. Basic Template Rendering
```bash
# Render all templates
helm template frontend ./frontend-chart

# Render with specific release name
helm template my-release ./frontend-chart
```

### 2. Render with Custom Values
```bash
# Override single value
helm template frontend ./frontend-chart --set replicaCount=3

# Override multiple values
helm template frontend ./frontend-chart \
  --set replicaCount=3 \
  --set image.tag=v2 \
  --set service.nodePort=30081

# Use custom values file
helm template frontend ./frontend-chart -f custom-values.yaml
```

### 3. Render Specific Template
```bash
# Show only deployment
helm template frontend ./frontend-chart -s templates/deployment.yaml

# Show only service
helm template frontend ./frontend-chart -s templates/service.yaml

# Show only configmap
helm template frontend ./frontend-chart -s templates/configmap.yaml
```

### 4. Debug Mode
```bash
# Show debug information with values
helm template frontend ./frontend-chart --debug

# Debug with custom values
helm template frontend ./frontend-chart --debug --set replicaCount=10
```

### 5. Set Namespace
```bash
# Render with specific namespace
helm template frontend ./frontend-chart --namespace production

# Render with namespace and create flag
helm template frontend ./frontend-chart \
  --namespace dev \
  --create-namespace
```

### 6. Save Output
```bash
# Save to file
helm template frontend ./frontend-chart > rendered.yaml

# Save specific template
helm template frontend ./frontend-chart -s templates/deployment.yaml > deployment.yaml
```

## Validation Commands

### 7. Lint Chart
```bash
# Basic lint
helm lint ./frontend-chart

# Strict linting
helm lint ./frontend-chart --strict

# Lint with custom values
helm lint ./frontend-chart -f production-values.yaml
```

### 8. Dry Run Install
```bash
# Dry run (validates against cluster)
helm install frontend ./frontend-chart --dry-run

# Dry run with debug
helm install frontend ./frontend-chart --dry-run --debug

# Dry run with custom namespace
helm install frontend ./frontend-chart \
  --dry-run \
  --namespace dev \
  --create-namespace
```

### 9. Validate Against Kubernetes
```bash
# Using kubectl dry-run
helm template frontend ./frontend-chart | kubectl apply --dry-run=client -f -

# Using kubectl diff (requires installed release)
helm template frontend ./frontend-chart | kubectl diff -f -
```

## Chart Information Commands

### 10. Show Chart Details
```bash
# Show chart metadata
helm show chart ./frontend-chart

# Show default values
helm show values ./frontend-chart

# Show everything
helm show all ./frontend-chart

# Show README
helm show readme ./frontend-chart
```

## Advanced Template Commands

### 11. Multiple Values Files
```bash
# Load multiple values files (last one wins for conflicts)
helm template frontend ./frontend-chart \
  -f values.yaml \
  -f dev-values.yaml \
  -f override-values.yaml
```

### 12. Complex Value Setting
```bash
# Set nested values
helm template frontend ./frontend-chart \
  --set image.repository=myrepo/myapp \
  --set image.tag=v2.0

# Set array values
helm template frontend ./frontend-chart \
  --set 'tolerations[0].key=node-role' \
  --set 'tolerations[0].operator=Equal' \
  --set 'tolerations[0].value=worker'

# Set map values
helm template frontend ./frontend-chart \
  --set 'podLabels.environment=prod' \
  --set 'podLabels.team=backend'
```

### 13. JSON/YAML Values from File
```bash
# Read values from JSON
helm template frontend ./frontend-chart --set-json 'configMap.data={"key":"value"}'

# Set file content as value
helm template frontend ./frontend-chart --set-file config=./myconfig.txt
```

## Practical Examples

### Example 1: Development Environment
```bash
helm template frontend ./frontend-chart \
  --namespace dev \
  --set replicaCount=2 \
  --set image.tag=dev-latest \
  --set service.nodePort=30090
```

### Example 2: Production Environment
```bash
helm template frontend ./frontend-chart \
  --namespace production \
  --set replicaCount=5 \
  --set image.tag=v1.0.0 \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=512Mi
```

### Example 3: Render and Apply
```bash
# Render and review
helm template frontend ./frontend-chart > /tmp/manifests.yaml
cat /tmp/manifests.yaml

# Apply to cluster
kubectl apply -f /tmp/manifests.yaml
```

### Example 4: Compare Versions
```bash
# Current version
helm template frontend ./frontend-chart > current.yaml

# New version with changes
helm template frontend ./frontend-chart --set image.tag=v2 > new.yaml

# Compare
diff current.yaml new.yaml
```

### Example 5: Full Validation Pipeline
```bash
# Step 1: Lint
helm lint ./frontend-chart

# Step 2: Template with debug
helm template frontend ./frontend-chart --debug

# Step 3: Dry-run install
helm install frontend ./frontend-chart --dry-run

# Step 4: Validate with kubectl
helm template frontend ./frontend-chart | kubectl apply --dry-run=client -f -
```

## Output Formatting

### Filter Specific Resources
```bash
# Show only Deployments
helm template frontend ./frontend-chart | grep -A 100 "kind: Deployment"

# Show only Services
helm template frontend ./frontend-chart | grep -A 50 "kind: Service"

# Count resources
helm template frontend ./frontend-chart | grep -c "^kind:"
```

### Pretty Print with yq (if installed)
```bash
# Pretty print YAML
helm template frontend ./frontend-chart | yq eval '.'

# Extract specific field
helm template frontend ./frontend-chart -s templates/deployment.yaml | \
  yq eval '.spec.replicas'
```

## Troubleshooting Commands

### Debug Template Errors
```bash
# Show detailed error information
helm template frontend ./frontend-chart --debug 2>&1

# Validate specific template
helm template frontend ./frontend-chart -s templates/deployment.yaml --debug
```

### Check Computed Values
```bash
# Show all computed values
helm template frontend ./frontend-chart --debug 2>&1 | grep -A 1000 "COMPUTED VALUES"

# Show user-supplied values
helm template frontend ./frontend-chart --debug 2>&1 | grep -A 1000 "USER-SUPPLIED VALUES"
```

## Common Flags

| Flag | Description |
|------|-------------|
| `--debug` | Enable verbose output |
| `--dry-run` | Simulate install/upgrade |
| `--namespace` | Kubernetes namespace |
| `--set` | Set values on command line |
| `-f, --values` | Specify values file |
| `-s, --show-only` | Show specific template |
| `--create-namespace` | Create namespace if needed |
| `--output-dir` | Write templates to directory |
| `--validate` | Validate manifests against cluster |

## Pro Tips

1. **Always test with `--debug`** to see computed values
2. **Use `--dry-run`** before actual installation
3. **Combine lint + template + dry-run** for full validation
4. **Save rendered templates** for review and troubleshooting
5. **Use specific templates** (`-s`) when debugging issues
6. **Test with different namespaces** to ensure portability

## Quick Test Workflow

```bash
# 1. Lint the chart
helm lint ./frontend-chart

# 2. Render templates
helm template frontend ./frontend-chart

# 3. Dry-run installation
helm install frontend ./frontend-chart --dry-run --debug

# 4. If all good, install
helm install frontend ./frontend-chart

# 5. Verify installation
helm list
kubectl get all -l app.kubernetes.io/instance=frontend
```
