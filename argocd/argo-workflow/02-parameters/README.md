# Argo Workflows - Parameters

## What You'll Learn

1. Input parameters to workflows
2. Output parameters from templates
3. Passing parameters between steps
4. Global parameters

---

## Parameter Types

### 1. Workflow Parameters (Global Inputs)
```yaml
spec:
  arguments:
    parameters:
      - name: message
        value: "default value"
```

### 2. Template Input Parameters
```yaml
templates:
  - name: my-template
    inputs:
      parameters:
        - name: param1
```

### 3. Template Output Parameters
```yaml
templates:
  - name: my-template
    outputs:
      parameters:
        - name: result
          valueFrom:
            path: /tmp/result.txt
```

---

## Parameter Syntax

| Syntax | Description |
|--------|-------------|
| `{{inputs.parameters.name}}` | Access input parameter |
| `{{outputs.parameters.name}}` | Access output parameter |
| `{{workflow.parameters.name}}` | Access workflow-level parameter |
| `{{steps.step-name.outputs.parameters.name}}` | Access output from a step |
| `{{tasks.task-name.outputs.parameters.name}}` | Access output from a DAG task |

---

## Submitting with Parameters

```bash
# Submit with parameter override
argo submit workflow.yaml -p message="Hello"

# Submit with multiple parameters
argo submit workflow.yaml -p name="John" -p age="30"

# Submit with parameter file
argo submit workflow.yaml --parameter-file params.yaml
```

---

## Files in this Directory

| File | Description |
|------|-------------|
| `01-input-params.yaml` | Basic input parameters |
| `02-output-params.yaml` | Capturing outputs |
| `03-passing-params.yaml` | Passing between steps |
| `04-global-params.yaml` | Workflow-level parameters |
