# Argo Workflows - Artifacts

## What are Artifacts?

Artifacts are **files** passed between workflow steps. Unlike parameters (small text values), artifacts can be large files like:
- Build outputs
- Test reports
- Data files
- Models

---

## Artifact Storage Options

| Storage | Description |
|---------|-------------|
| **Emissary** | Default, passes via volume (no external storage) |
| **S3** | Amazon S3 or S3-compatible (MinIO) |
| **GCS** | Google Cloud Storage |
| **Azure Blob** | Azure Blob Storage |
| **HTTP** | HTTP/HTTPS endpoints |
| **Git** | Git repositories |

---

## Artifact Syntax

### Output Artifact
```yaml
outputs:
  artifacts:
    - name: my-artifact
      path: /tmp/output-file.txt
```

### Input Artifact
```yaml
inputs:
  artifacts:
    - name: my-artifact
      path: /tmp/input-file.txt
```

---

## Passing Artifacts Between Steps

```yaml
steps:
  - - name: generate
      template: producer
  - - name: consume
      template: consumer
      arguments:
        artifacts:
          - name: input-data
            from: "{{steps.generate.outputs.artifacts.output-data}}"
```

---

## Files in this Directory

| File | Description |
|------|-------------|
| `01-simple-artifact.yaml` | Basic artifact passing |
| `02-s3-artifacts.yaml` | Using S3/MinIO for artifacts |
| `03-artifact-repository.yaml` | Default artifact repository config |
