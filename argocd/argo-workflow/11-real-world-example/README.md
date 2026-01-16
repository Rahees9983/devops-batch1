# Real-World Argo Workflow Examples

This directory contains production-ready workflow examples that demonstrate most Argo Workflow features in realistic scenarios.

## Examples

| File | Description | Use Case |
|------|-------------|----------|
| [01-complete-cicd-pipeline.yaml](01-complete-cicd-pipeline.yaml) | Complete CI/CD pipeline | Node.js microservice deployment |
| [02-data-processing-pipeline.yaml](02-data-processing-pipeline.yaml) | ETL data pipeline | Data warehouse loading |

---

## 01. Complete CI/CD Pipeline

A comprehensive CI/CD pipeline for a Node.js application with all stages from code checkout to production deployment.

### Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CI/CD PIPELINE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐                                                       │
│  │  Clone   │                                                       │
│  │   Repo   │                                                       │
│  └────┬─────┘                                                       │
│       │                                                             │
│       ▼                                                             │
│  ┌──────────┐                                                       │
│  │  Install │                                                       │
│  │   Deps   │                                                       │
│  └────┬─────┘                                                       │
│       │                                                             │
│       ├────────────┬────────────┐                                   │
│       ▼            ▼            ▼                                   │
│  ┌────────┐  ┌──────────┐  ┌──────────┐                            │
│  │  Lint  │  │  Tests   │  │ Security │  (Parallel)                │
│  └────┬───┘  └────┬─────┘  └────┬─────┘                            │
│       │           │             │                                   │
│       └─────┬─────┴─────────────┘                                   │
│             ▼                                                       │
│  ┌────────────────────┐                                             │
│  │ Integration Tests  │  (with PostgreSQL daemon)                   │
│  └─────────┬──────────┘                                             │
│            ▼                                                        │
│  ┌──────────────┐                                                   │
│  │    Build     │                                                   │
│  │  Docker Image│                                                   │
│  └──────┬───────┘                                                   │
│         ▼                                                           │
│  ┌────────────────┐                                                 │
│  │    Deploy      │                                                 │
│  │   Staging      │                                                 │
│  └───────┬────────┘                                                 │
│          ▼                                                          │
│  ┌────────────────┐                                                 │
│  │  Smoke Tests   │                                                 │
│  └───────┬────────┘                                                 │
│          ▼                                                          │
│  ┌────────────────┐                                                 │
│  │    Manual      │  (Production only - Suspend template)           │
│  │   Approval     │                                                 │
│  └───────┬────────┘                                                 │
│          ▼                                                          │
│  ┌────────────────┐                                                 │
│  │    Deploy      │                                                 │
│  │  Production    │                                                 │
│  └────────────────┘                                                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Features Demonstrated

| Feature | Implementation |
|---------|----------------|
| **DAG Orchestration** | Main pipeline with complex dependencies |
| **Steps** | Exit handler with sequential steps |
| **Parameters** | Global and task-level parameters |
| **Artifacts** | Security report, test report, build manifest |
| **Container Template** | Most tasks |
| **Script Template** | Lint task |
| **HTTP Template** | Health check verification |
| **Suspend Template** | Manual approval gate |
| **Daemon Containers** | PostgreSQL for integration tests |
| **Conditionals (when)** | Production-only steps, Slack toggle |
| **Retry + Backoff** | npm install, smoke tests |
| **Timeouts** | Workflow and task level |
| **Exit Handlers** | Notification, cleanup, alerting |
| **Resource Limits** | Memory/CPU on containers |
| **Volume Claims** | Shared workspace |
| **Artifact GC** | OnWorkflowDeletion |

### How to Run

```bash
# Basic run (staging deployment)
argo submit -n argo 01-complete-cicd-pipeline.yaml --watch

# Production deployment (requires manual approval)
argo submit -n argo 01-complete-cicd-pipeline.yaml \
  -p environment=production \
  -p git-branch=main \
  --watch

# Resume after manual approval
argo resume <workflow-name> -n argo

# Custom repository
argo submit -n argo 01-complete-cicd-pipeline.yaml \
  -p git-repo="https://github.com/myorg/myapp" \
  -p git-branch="feature/new-feature" \
  -p notify-slack="false" \
  --watch
```

---

## 02. Data Processing Pipeline

An ETL (Extract, Transform, Load) pipeline that processes data from multiple sources and loads to a data warehouse.

### Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────────┐
│                      DATA PIPELINE                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────┐              │
│  │              EXTRACT (withParam loop)             │              │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐ │              │
│  │  │Customers │ │ Orders   │ │ Products │ │Invent│ │  (Parallel)  │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──┬───┘ │              │
│  │       └────────────┴────────────┴──────────┘     │              │
│  │                        │                         │              │
│  │                        ▼                         │              │
│  │                  ┌──────────┐                    │              │
│  │                  │ Combine  │                    │              │
│  │                  └────┬─────┘                    │              │
│  └───────────────────────┼──────────────────────────┘              │
│                          │                                          │
│                          ▼                                          │
│                  ┌───────────────┐                                  │
│                  │Quality Checks │  (Conditional)                   │
│                  └───────┬───────┘                                  │
│                          │                                          │
│  ┌───────────────────────┼──────────────────────────┐              │
│  │              TRANSFORM (Sequential)              │              │
│  │                       ▼                          │              │
│  │  ┌───────┐  ┌───────────┐  ┌───────────┐  ┌────┐│              │
│  │  │ Clean │→ │ Normalize │→ │ Aggregate │→ │Enri││              │
│  │  └───────┘  └───────────┘  └───────────┘  └──┬─┘│              │
│  └──────────────────────────────────────────────┼───┘              │
│                                                 │                   │
│                                                 ▼                   │
│                                      ┌──────────────────┐          │
│                                      │ Load to Warehouse│          │
│                                      └────────┬─────────┘          │
│                                               │                     │
│                                               ▼                     │
│                            ┌──────────────────────────────┐        │
│                            │      GENERATE REPORTS        │        │
│                            │  ┌─────────┐ ┌─────┐ ┌─────┐│        │
│                            │  │ Daily   │ │Cust │ │Sales││(Parallel)
│                            │  │ Summary │ │Anlyt│ │Metr ││        │
│                            │  └─────────┘ └─────┘ └─────┘│        │
│                            └──────────────────────────────┘        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Features Demonstrated

| Feature | Implementation |
|---------|----------------|
| **withParam Loop** | Extract multiple data sources in parallel |
| **Artifact Passing** | Data flows through transformation stages |
| **Steps within DAG** | Transform pipeline as sequential steps |
| **Conditional Execution** | Quality checks toggle |
| **Retry Strategy** | Extract and load operations |
| **Exit Handler** | Cleanup and debug preservation |
| **Parallel Tasks** | Report generation |

### How to Run

```bash
# Basic run
argo submit -n argo 02-data-processing-pipeline.yaml --watch

# Custom date and sources
argo submit -n argo 02-data-processing-pipeline.yaml \
  -p run-date="2024-01-20" \
  -p data-sources='["customers", "orders"]' \
  --watch

# Disable quality checks
argo submit -n argo 02-data-processing-pipeline.yaml \
  -p enable-quality-checks="false" \
  --watch
```

---

## Feature Coverage Summary

| Feature | CI/CD Pipeline | Data Pipeline |
|---------|:--------------:|:-------------:|
| DAG Orchestration | ✅ | ✅ |
| Steps Orchestration | ✅ | ✅ |
| Parameters | ✅ | ✅ |
| Artifacts | ✅ | ✅ |
| Container Template | ✅ | ✅ |
| Script Template | ✅ | ✅ |
| HTTP Template | ✅ | - |
| Suspend Template | ✅ | - |
| Daemon Containers | ✅ | - |
| Conditionals (when) | ✅ | ✅ |
| Loops (withParam) | - | ✅ |
| Retry + Backoff | ✅ | ✅ |
| Timeouts | ✅ | ✅ |
| Exit Handlers | ✅ | ✅ |
| Resource Limits | ✅ | ✅ |
| Volume Claims | ✅ | - |
| Artifact GC | ✅ | - |

---

## Prerequisites

Before running these examples, ensure:

1. **Argo Workflows is installed**
   ```bash
   kubectl get pods -n argo
   ```

2. **Service Account exists**
   ```bash
   kubectl get sa argo-workflow -n argo
   ```

3. **RBAC permissions are configured**
   ```bash
   kubectl get clusterrolebinding argo-workflow-binding
   ```

See the [installation guide](../00-installation/) for setup instructions.

---

## Customization Tips

### Adding Real Git Clone
Replace the simulated git clone with:
```yaml
- name: git-clone
  container:
    image: alpine/git
    command: [sh, -c]
    args:
      - |
        git clone --branch {{inputs.parameters.branch}} \
          {{inputs.parameters.repo}} /workspace/app
```

### Adding Real Docker Build (Kaniko)
```yaml
- name: build-docker-image
  container:
    image: gcr.io/kaniko-project/executor:latest
    args:
      - --dockerfile=/workspace/app/Dockerfile
      - --context=/workspace/app
      - --destination={{workflow.parameters.image-registry}}/{{workflow.parameters.image-name}}:{{inputs.parameters.image-tag}}
```

### Adding Real Slack Notification
```yaml
- name: slack-notification
  container:
    image: curlimages/curl
    env:
      - name: SLACK_WEBHOOK
        valueFrom:
          secretKeyRef:
            name: slack-secrets
            key: webhook-url
    command: [sh, -c]
    args:
      - |
        curl -X POST $SLACK_WEBHOOK \
          -H 'Content-Type: application/json' \
          -d '{"text": "{{inputs.parameters.message}}"}'
```
