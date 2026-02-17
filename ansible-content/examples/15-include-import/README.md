# Include and Import

## Overview

Ansible provides two ways to reuse content:
- **include_*** - Dynamic (runtime)
- **import_*** - Static (parse time)

## Key Differences

| Feature | include_* | import_* |
|---------|-----------|----------|
| Processing | Runtime | Parse time |
| Conditionals | Apply to include itself | Apply to each task |
| Loops | Supported | Not supported |
| Tags | Cannot tag included tasks | Can tag imported tasks |
| Handlers | Can notify | Can notify |
| Variables | Uses current values | Uses parse-time values |

## Task Inclusion

```yaml
# Dynamic (runtime)
- include_tasks: tasks/setup.yml

# Static (parse time)
- import_tasks: tasks/setup.yml
```

## Role Inclusion

```yaml
# Dynamic
- include_role:
    name: webserver

# Static
- import_role:
    name: webserver
```

## Variable Inclusion

```yaml
# Include variables
- include_vars: vars/production.yml

# Include based on OS
- include_vars: "vars/{{ ansible_os_family }}.yml"
```

## Playbook Import

```yaml
# site.yml
- import_playbook: webservers.yml
- import_playbook: dbservers.yml
```

## Best Practices

1. Use **import** for static, predictable content
2. Use **include** for dynamic, conditional content
3. Use **import** when you need to apply tags
4. Use **include** with loops

See example files for detailed demonstrations.
