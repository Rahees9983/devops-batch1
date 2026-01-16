# Argo Workflows - Loops and Conditionals

## What You'll Learn

1. Looping over lists
2. Looping over JSON items
3. Conditional execution with `when`
4. Dynamic task generation

---

## Loop Syntax

### Simple List Loop
```yaml
steps:
  - - name: process-item
      template: my-template
      arguments:
        parameters:
          - name: item
            value: "{{item}}"
      withItems:
        - apple
        - banana
        - cherry
```

### Loop with JSON Objects
```yaml
withItems:
  - { name: "app1", port: 8080 }
  - { name: "app2", port: 8081 }
```

### Loop with Parameter
```yaml
withParam: "{{workflow.parameters.items}}"
```

---

## Conditional Syntax

```yaml
- name: conditional-step
  template: my-template
  when: "{{steps.check.outputs.result}} == pass"
```

---

## Files in this Directory

| File | Description |
|------|-------------|
| `01-loops.yaml` | Basic loops |
| `02-conditionals.yaml` | When conditions |
| `03-loop-with-map.yaml` | Loop with JSON objects |
