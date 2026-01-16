# Argo Workflow Template Types

This directory contains individual examples for each Argo Workflow template type.

## Template Categories

Argo Workflows has two categories of templates:

### 1. Template Definitions (What to Run)
These define the actual work to be done:

| Template | File | Description |
|----------|------|-------------|
| Container | [01-container-template.yaml](01-container-template.yaml) | Run a single container (most common) |
| Script | [02-script-template.yaml](02-script-template.yaml) | Run inline code (Python, Bash, etc.) |
| Resource | [03-resource-template.yaml](03-resource-template.yaml) | Create/manage Kubernetes resources |
| Suspend | [04-suspend-template.yaml](04-suspend-template.yaml) | Pause workflow for approval/delay |
| Container Set | [05-container-set-template.yaml](05-container-set-template.yaml) | Multiple containers in one pod |
| HTTP | [06-http-template.yaml](06-http-template.yaml) | Make HTTP requests (no container) |
| Plugin | (Advanced) | Custom executor plugins |

### 2. Template Invocators (How to Orchestrate)
These orchestrate the execution of template definitions:

| Invocator | File | Description |
|-----------|------|-------------|
| Steps | [07-steps-invocator.yaml](07-steps-invocator.yaml) | Sequential/parallel by array level |
| DAG | [08-dag-invocator.yaml](08-dag-invocator.yaml) | Dependency-based execution |

### 3. Reusable Templates (Define Once, Use Many)
These allow you to create reusable workflow definitions:

| Type | File | Description |
|------|------|-------------|
| WorkflowTemplate | [09-workflow-template.yaml](09-workflow-template.yaml) | Namespaced reusable workflows |
| ClusterWorkflowTemplate | [10-cluster-workflow-template.yaml](10-cluster-workflow-template.yaml) | Cluster-wide reusable workflows |

## Visual Overview

```
┌─────────────────────────────────────────────────────────────┐
│              TEMPLATE DEFINITIONS                           │
│              (What to run)                                  │
├─────────────────┬───────────────────────────────────────────┤
│ Container       │ Single container (most common)            │
│ Script          │ Inline code (Python, Bash, Node.js)       │
│ Resource        │ Create K8s resources (ConfigMap, Job)     │
│ Suspend         │ Pause for approval/delay                  │
│ Container Set   │ Multiple containers in one pod            │
│ HTTP            │ HTTP requests (lightweight, no container) │
│ Plugin          │ Custom executor (advanced)                │
└─────────────────┴───────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              TEMPLATE INVOCATORS                            │
│              (How to orchestrate)                           │
├─────────────────┬───────────────────────────────────────────┤
│ Steps           │ Sequential/parallel by array level        │
│ DAG             │ Dependency-based execution graph          │
└─────────────────┴───────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              REUSABLE TEMPLATES                             │
│              (Define once, use many)                        │
├─────────────────────────┬───────────────────────────────────┤
│ WorkflowTemplate        │ Namespaced (team-specific)        │
│ ClusterWorkflowTemplate │ Cluster-wide (org-wide)           │
└─────────────────────────┴───────────────────────────────────┘
```

## Quick Reference: When to Use What

### Template Definitions

| Use Case | Template |
|----------|----------|
| Running CLI tools (aws, kubectl) | Container |
| Quick one-off scripts | Script |
| Provisioning infrastructure | Resource |
| Manual approval gates | Suspend |
| Sidecar patterns | Container Set |
| API calls, webhooks | HTTP |

### Template Invocators

| Use Case | Invocator |
|----------|-----------|
| Simple linear pipelines | Steps |
| Basic parallel + sequential | Steps |
| Complex dependency graphs | DAG |
| Diamond patterns | DAG |
| Maximum parallelism | DAG |

## Running the Examples

```bash
# Submit individual examples
argo submit -n argo 01-container-template.yaml --watch
argo submit -n argo 02-script-template.yaml --watch
argo submit -n argo 03-resource-template.yaml --watch
argo submit -n argo 04-suspend-template.yaml --watch
argo submit -n argo 05-container-set-template.yaml --watch
argo submit -n argo 06-http-template.yaml --watch
argo submit -n argo 07-steps-invocator.yaml --watch
argo submit -n argo 08-dag-invocator.yaml --watch

# WorkflowTemplate and ClusterWorkflowTemplate
# First, apply the templates:
kubectl apply -n argo -f 09-workflow-template.yaml
kubectl apply -f 10-cluster-workflow-template.yaml  # No namespace (cluster-scoped)

# Then submit workflows from templates:
argo submit -n argo --from workflowtemplate/build-and-deploy --watch
argo submit -n argo --from clusterworkflowtemplate/common-ci \
  -p repo-url="https://github.com/myorg/myapp" --watch

# Or run the combined example from parent directory
argo submit -n argo ../06-all-template-types.yaml --watch
```

## Steps vs DAG Comparison

### Steps (Array-based)
```yaml
steps:
  - - name: step-1        # Sequential
      template: task

  - - name: step-2a       # Parallel
      template: task
    - name: step-2b       # Same level = parallel
      template: task

  - - name: step-3        # Sequential (waits for step-2)
      template: task
```

### DAG (Dependency-based)
```yaml
dag:
  tasks:
    - name: task-a        # No deps - starts immediately
      template: work

    - name: task-b
      dependencies: [task-a]
      template: work

    - name: task-c
      dependencies: [task-a]
      template: work

    - name: task-d
      dependencies: [task-b, task-c]  # Waits for both
      template: work
```

## See Also

- [06-all-template-types.yaml](../06-all-template-types.yaml) - All templates in one file
- [Main Guide](../../ARGO-WORKFLOW-GUIDE.md) - Complete learning guide
