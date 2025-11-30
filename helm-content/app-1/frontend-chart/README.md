# Frontend Helm Chart

This Helm chart deploys a frontend application with ConfigMap, ServiceAccount, and security contexts.

## Chart Structure

```
frontend-chart/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
└── templates/
    ├── _helpers.tpl        # Template helpers
    ├── deployment.yaml     # Deployment template
    ├── service.yaml        # Service template
    ├── configmap.yaml      # ConfigMap template
    └── serviceaccount.yaml # ServiceAccount template
```

## Installation

### Install the chart
```bash
helm install frontend ./frontend-chart
```

### Install with custom namespace
```bash
helm install frontend ./frontend-chart --namespace dev --create-namespace
```

### Install with custom values
```bash
helm install frontend ./frontend-chart --set replicaCount=3 --set image.tag=v2
```

### Install with values file
```bash
helm install frontend ./frontend-chart -f custom-values.yaml
```

## Upgrade

```bash
helm upgrade frontend ./frontend-chart
```

## Uninstall

```bash
helm uninstall frontend
```

## Configuration

Key configurable values in `values.yaml`:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `5` |
| `image.repository` | Image repository | `rahees9983/deployment-strategy-app` |
| `image.tag` | Image tag | `v1` |
| `service.type` | Service type | `NodePort` |
| `service.nodePort` | NodePort value | `30080` |
| `serviceAccount.create` | Create service account | `true` |
| `configMap.create` | Create config map | `true` |

## Testing

### Lint the chart
```bash
helm lint ./frontend-chart
```

### Dry run installation
```bash
helm install frontend ./frontend-chart --dry-run --debug
```

### Template rendering
```bash
helm template frontend ./frontend-chart
```

## Features

- ✅ ServiceAccount with configurable automount
- ✅ ConfigMap for application configuration
- ✅ Security contexts (pod and container level)
- ✅ Configurable rolling update strategy
- ✅ NodePort service with customizable port
- ✅ Volume mounts for ConfigMap
- ✅ Resource limits and requests (optional)
- ✅ Node selector, tolerations, and affinity (optional)
