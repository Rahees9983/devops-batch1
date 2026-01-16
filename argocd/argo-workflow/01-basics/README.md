# Argo Workflows - Basics

## Argo Workflows Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              KUBERNETES CLUSTER                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         ARGO WORKFLOWS NAMESPACE                           │ │
│  ├────────────────────────────────────────────────────────────────────────────┤ │
│  │                                                                            │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │ │
│  │  │                    ARGO WORKFLOW CONTROLLER                         │  │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │  │ │
│  │  │  │ Workflow        │  │ Template        │  │ Event               │ │  │ │
│  │  │  │ Reconciler      │  │ Resolution      │  │ Processing          │ │  │ │
│  │  │  │                 │  │                 │  │                     │ │  │ │
│  │  │  │ - Watch CRDs    │  │ - Resolve refs  │  │ - Handle triggers   │ │  │ │
│  │  │  │ - Create Pods   │  │ - Parameter     │  │ - Cron scheduling   │ │  │ │
│  │  │  │ - Track status  │  │   substitution  │  │ - Webhooks          │ │  │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────────┘ │  │ │
│  │  └─────────────────────────────────────────────────────────────────────┘  │ │
│  │                                    │                                       │ │
│  │                                    │ Watches & Creates                     │ │
│  │                                    ▼                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │ │
│  │  │                    KUBERNETES API SERVER                            │  │ │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │  │ │
│  │  │  │  Workflow    │  │ WorkflowTpl  │  │ CronWorkflow │              │  │ │
│  │  │  │  CRD         │  │ CRD          │  │ CRD          │              │  │ │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘              │  │ │
│  │  └─────────────────────────────────────────────────────────────────────┘  │ │
│  │                                    │                                       │ │
│  │                                    │ Creates                               │ │
│  │                                    ▼                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │ │
│  │  │                    WORKFLOW EXECUTION                               │  │ │
│  │  │                                                                     │  │ │
│  │  │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐            │  │ │
│  │  │   │   Pod A     │    │   Pod B     │    │   Pod C     │            │  │ │
│  │  │   │  (Step 1)   │───▶│  (Step 2)   │───▶│  (Step 3)   │            │  │ │
│  │  │   │             │    │             │    │             │            │  │ │
│  │  │   │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │            │  │ │
│  │  │   │ │  Main   │ │    │ │  Main   │ │    │ │  Main   │ │            │  │ │
│  │  │   │ │Container│ │    │ │Container│ │    │ │Container│ │            │  │ │
│  │  │   │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │            │  │ │
│  │  │   │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │            │  │ │
│  │  │   │ │  Wait   │ │    │ │  Wait   │ │    │ │  Wait   │ │            │  │ │
│  │  │   │ │Container│ │    │ │Container│ │    │ │Container│ │            │  │ │
│  │  │   │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │            │  │ │
│  │  │   └─────────────┘    └─────────────┘    └─────────────┘            │  │ │
│  │  │                                                                     │  │ │
│  │  └─────────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                            │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌──────────────────────────────────┐  ┌──────────────────────────────────────┐ │
│  │     ARGO SERVER (UI + API)       │  │       ARTIFACT REPOSITORY            │ │
│  │  ┌────────────────────────────┐  │  │  ┌────────────────────────────────┐  │ │
│  │  │  - Web UI Dashboard        │  │  │  │  S3 / MinIO / GCS / Artifactory│  │ │
│  │  │  - REST API                │  │  │  │                                │  │ │
│  │  │  - SSO Authentication      │  │  │  │  - Store workflow artifacts    │  │ │
│  │  │  - Workflow submission     │  │  │  │  - Pass data between steps     │  │ │
│  │  │  - Log viewing             │  │  │  │  - Archive outputs             │  │ │
│  │  └────────────────────────────┘  │  │  └────────────────────────────────┘  │ │
│  └──────────────────────────────────┘  └──────────────────────────────────────┘ │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘

                                    │
                                    │ Users interact via
                                    ▼

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              USER INTERFACES                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   ┌───────────────┐    ┌───────────────┐    ┌───────────────┐                   │
│   │   Argo CLI    │    │   Web UI      │    │   REST API    │                   │
│   │               │    │               │    │               │                   │
│   │ argo submit   │    │  Dashboard    │    │  POST /api/   │                   │
│   │ argo list     │    │  Logs viewer  │    │  v1/workflows │                   │
│   │ argo logs     │    │  DAG viewer   │    │               │                   │
│   └───────────────┘    └───────────────┘    └───────────────┘                   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

| Component | Description |
|-----------|-------------|
| **Workflow Controller** | Core component that watches Workflow CRDs and creates Pods |
| **Argo Server** | Provides Web UI and REST API for workflow management |
| **Workflow CRD** | Custom Resource Definition for workflow specifications |
| **WorkflowTemplate CRD** | Reusable workflow definitions (namespaced) |
| **ClusterWorkflowTemplate CRD** | Cluster-wide reusable workflow definitions |
| **CronWorkflow CRD** | Scheduled workflow execution |
| **Wait Container** | Sidecar that handles artifact passing and status reporting |
| **Artifact Repository** | External storage (S3/MinIO/GCS) for workflow artifacts |

## Workflow Execution Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   User       │     │  API Server  │     │  Controller  │     │  Kubernetes  │
│  (CLI/UI)    │     │              │     │              │     │              │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │                    │
       │ 1. Submit Workflow │                    │                    │
       │───────────────────▶│                    │                    │
       │                    │                    │                    │
       │                    │ 2. Store Workflow  │                    │
       │                    │       CRD          │                    │
       │                    │───────────────────▶│                    │
       │                    │                    │                    │
       │                    │                    │ 3. Watch detects   │
       │                    │                    │    new workflow    │
       │                    │                    │◀───────────────────│
       │                    │                    │                    │
       │                    │                    │ 4. Create Pod for  │
       │                    │                    │    first step      │
       │                    │                    │───────────────────▶│
       │                    │                    │                    │
       │                    │                    │ 5. Pod completes   │
       │                    │                    │◀───────────────────│
       │                    │                    │                    │
       │                    │                    │ 6. Update status   │
       │                    │                    │    & create next   │
       │                    │                    │    Pod             │
       │                    │                    │───────────────────▶│
       │                    │                    │                    │
       │                    │ 7. Workflow        │                    │
       │ 8. Get Status      │    Complete        │                    │
       │◀───────────────────│◀───────────────────│                    │
       │                    │                    │                    │
```

---

## What You'll Learn

1. Hello World workflow
2. Multi-step sequential workflows
3. Parallel execution
4. Script templates

---

## Workflow Structure Explained

```yaml
apiVersion: argoproj.io/v1alpha1    # API version
kind: Workflow                       # Resource type
metadata:
  generateName: hello-world-         # Prefix for auto-generated name
spec:
  entrypoint: main                   # Which template to start with
  templates:                         # List of templates
    - name: main                     # Template name
      container:                     # Container spec (like a Pod)
        image: alpine:latest
        command: [echo]
        args: ["Hello, World!"]
```

---

## Template Types

### 1. Container Template
Runs a single container:
```yaml
- name: my-container
  container:
    image: alpine
    command: [echo, "hello"]
```

### 2. Script Template
Runs inline scripts:
```yaml
- name: my-script
  script:
    image: python:3.9
    command: [python]
    source: |
      print("Hello from Python!")
```

### 3. Steps Template
Sequential/parallel steps:
```yaml
- name: my-steps
  steps:
    - - name: step1           # First step
        template: task1
    - - name: step2a          # Parallel steps
        template: task2
      - name: step2b
        template: task2
```

### 4. DAG Template
Dependency-based execution:
```yaml
- name: my-dag
  dag:
    tasks:
      - name: A
        template: task
      - name: B
        dependencies: [A]
        template: task
```

---

## Running Workflows

```bash
# Submit workflow
argo submit -n argo 01-hello-world.yaml

# Submit and watch
argo submit -n argo 01-hello-world.yaml --watch

# Submit with auto-generated name
argo submit -n argo 01-hello-world.yaml --generate-name

# List workflows
argo list -n argo

# Get workflow details
argo get -n argo <workflow-name>

# View logs
argo logs -n argo <workflow-name>

# Delete workflow
argo delete -n argo <workflow-name>
```

---

## Files in this Directory

| File | Description |
|------|-------------|
| `01-hello-world.yaml` | Simplest workflow - single container |
| `02-multi-step.yaml` | Sequential steps |
| `03-parallel-steps.yaml` | Parallel execution |
| `04-script-template.yaml` | Using inline scripts |
| `05-container-resources.yaml` | Setting CPU/memory limits |

---

## Practice Exercises

1. Modify hello-world to print your name
2. Add a third step to multi-step workflow
3. Create a workflow with 4 parallel steps
4. Write a script that calculates something
