# Argo Workflows - DAG (Directed Acyclic Graph)

## What is a DAG?

A DAG defines task dependencies explicitly. Tasks only run when their dependencies are complete.

```
    A
   / \
  B   C
   \ /
    D
```

In this DAG:
- A runs first
- B and C run in parallel after A
- D runs after both B and C complete

---

## DAG vs Steps

| Feature | Steps | DAG |
|---------|-------|-----|
| Execution Order | Sequential by default | Dependency-based |
| Parallelism | Explicit (same level) | Automatic |
| Dependencies | Implicit (order) | Explicit |
| Use Case | Simple pipelines | Complex dependencies |

---

## DAG Syntax

```yaml
templates:
  - name: my-dag
    dag:
      tasks:
        - name: A
          template: task-template

        - name: B
          dependencies: [A]      # Runs after A
          template: task-template

        - name: C
          dependencies: [A]      # Runs after A (parallel with B)
          template: task-template

        - name: D
          dependencies: [B, C]   # Runs after both B and C
          template: task-template
```

---

## Files in this Directory

| File | Description |
|------|-------------|
| `01-simple-dag.yaml` | Basic DAG example |
| `02-diamond-dag.yaml` | Diamond dependency pattern |
| `03-complex-dag.yaml` | Complex multi-path DAG |
