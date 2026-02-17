# Ansible Handlers

## What are Handlers?

Handlers are special tasks that only run when notified by other tasks. They are typically used to restart services after configuration changes.

## Key Characteristics

1. **Run at end of play** - Handlers execute after all tasks complete
2. **Run only once** - Even if notified multiple times
3. **Run in definition order** - Not notification order
4. **Require notification** - Won't run unless notified

## Basic Syntax

```yaml
tasks:
  - name: Update configuration
    template:
      src: config.j2
      dest: /etc/app/config.yml
    notify: Restart app

handlers:
  - name: Restart app
    service:
      name: myapp
      state: restarted
```

## Handler Features

- **notify** - Trigger handler from task
- **listen** - Multiple handlers respond to one event
- **meta: flush_handlers** - Run handlers immediately
- **force_handlers** - Run handlers even on failure

## Best Practices

1. Name handlers descriptively
2. Use handlers for service restarts/reloads
3. Consider using `listen` for grouped restarts
4. Use `flush_handlers` when subsequent tasks depend on service state
5. Keep handlers idempotent

See the example playbooks in this directory.
