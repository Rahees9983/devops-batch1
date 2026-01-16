# Argo Workflows - Complete Learning Guide

## What is Argo Workflows?

Argo Workflows is an open-source **container-native workflow engine** for orchestrating parallel jobs on Kubernetes. It enables you to define workflows where each step is a container.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ARGO WORKFLOWS OVERVIEW                          │
│                                                                         │
│   ┌─────────────┐                                                       │
│   │   WORKFLOW  │  = A sequence of tasks/steps                          │
│   └──────┬──────┘                                                       │
│          │                                                              │
│          ▼                                                              │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │
│   │   STEP 1    │───►│   STEP 2    │───►│   STEP 3    │                │
│   │ (Container) │    │ (Container) │    │ (Container) │                │
│   └─────────────┘    └─────────────┘    └─────────────┘                │
│                                                                         │
│   Each step runs in its own container (Pod)                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Why Use Argo Workflows?

| Feature | Description |
|---------|-------------|
| **Container Native** | Each step runs in a container |
| **DAG Support** | Define complex dependencies |
| **Parallelism** | Run steps in parallel |
| **Artifacts** | Pass data between steps |
| **Retry Logic** | Automatic retries on failure |
| **UI Dashboard** | Visual workflow monitoring |
| **CI/CD Pipelines** | Build, test, deploy automation |
| **Data Processing** | ETL, ML pipelines |

---

## Use Cases

1. **CI/CD Pipelines** - Build, test, deploy applications
2. **Data Processing** - ETL jobs, batch processing
3. **Machine Learning** - Training pipelines, model deployment
4. **Infrastructure Automation** - Provisioning, maintenance tasks
5. **Scheduled Jobs** - Cron-based workflows

---

## Core Concepts

### 1. Workflow
The main resource that defines your entire pipeline.

### 2. Template
A reusable definition of a step. Types:
- **Container** - Runs a single container
- **Script** - Runs inline scripts
- **DAG** - Defines task dependencies
- **Steps** - Sequential/parallel steps

### 3. Entrypoint
The starting template of the workflow.

### 4. Parameters
Inputs/outputs passed between templates.

### 5. Artifacts
Files passed between steps (S3, GCS, MinIO).

---

## Workflow Structure

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: my-workflow
spec:
  entrypoint: main          # Starting template
  templates:
    - name: main            # Template definition
      container:
        image: alpine
        command: [echo, "Hello"]
```

---

## Learning Path

```
📁 argo-workflow/
│
├── 00-installation/        # Install Argo Workflows
│   ├── install.yaml
│   └── README.md
│
├── 01-basics/              # Hello World, simple workflows
│   ├── 01-hello-world.yaml
│   ├── 02-multi-step.yaml
│   └── 03-parallel-steps.yaml
│
├── 02-parameters/          # Input/Output parameters
│   ├── 01-input-params.yaml
│   ├── 02-output-params.yaml
│   └── 03-global-params.yaml
│
├── 03-artifacts/           # File passing between steps
│   ├── 01-simple-artifact.yaml
│   └── 02-s3-artifacts.yaml
│
├── 04-dag-workflows/       # Directed Acyclic Graph
│   ├── 01-simple-dag.yaml
│   └── 02-diamond-dag.yaml
│
├── 05-loops-conditionals/  # Loops and when conditions
│   ├── 01-loops.yaml
│   └── 02-conditionals.yaml
│
├── 06-volumes/             # Persistent storage
│   └── 01-volume-workflow.yaml
│
├── 07-secrets/             # Using secrets
│   └── 01-secret-workflow.yaml
│
├── 08-ci-cd-example/       # Complete CI/CD pipeline
│   ├── ci-pipeline.yaml
│   └── cd-pipeline.yaml
│
├── 09-cron-workflows/      # Scheduled workflows
│   └── 01-cron-workflow.yaml
│
└── 10-advanced/            # Advanced patterns
    ├── 01-retry-backoff.yaml
    ├── 02-exit-handlers.yaml
    └── 03-resource-workflow.yaml
```

---

## Quick Start Commands

```bash
# Install Argo Workflows
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.5/install.yaml

# Install Argo CLI (Mac)
brew install argo

# Submit a workflow
argo submit -n argo workflow.yaml

# List workflows
argo list -n argo

# Watch workflow progress
argo watch -n argo <workflow-name>

# Get workflow logs
argo logs -n argo <workflow-name>

# Access UI (port-forward)
kubectl -n argo port-forward svc/argo-server 2746:2746
# Open: https://localhost:2746
```

---

## Comparison: Argo Workflows vs Others

| Feature | Argo Workflows | Jenkins | GitHub Actions |
|---------|---------------|---------|----------------|
| Kubernetes Native | Yes | No | No |
| Container-based | Yes | Partial | Yes |
| DAG Support | Yes | Limited | Limited |
| UI Dashboard | Yes | Yes | Yes |
| Self-hosted | Yes | Yes | No |
| Artifacts | Yes | Yes | Yes |
| Parallelism | Excellent | Good | Good |

---

## Next Steps

1. Start with `00-installation/` to install Argo Workflows
2. Practice `01-basics/` examples
3. Move through each folder sequentially
4. Build your own CI/CD pipeline in `08-ci-cd-example/`

Let's begin!
