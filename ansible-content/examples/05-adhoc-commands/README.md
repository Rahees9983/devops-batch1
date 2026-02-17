# Ad Hoc Commands

## Syntax

```bash
ansible <host-pattern> -m <module> -a "<arguments>" [options]
```

## Common Options

| Option | Description |
|--------|-------------|
| `-m` | Module name |
| `-a` | Module arguments |
| `-i` | Inventory file |
| `-b, --become` | Run with privilege escalation |
| `-K, --ask-become-pass` | Prompt for sudo password |
| `-u` | Remote user |
| `-k, --ask-pass` | Prompt for SSH password |
| `-f` | Number of forks (parallel processes) |
| `-v, -vv, -vvv` | Verbose output |
| `--check` | Dry run mode |

## Host Patterns

```bash
# All hosts
ansible all -m ping

# Specific group
ansible webservers -m ping

# Multiple groups
ansible 'webservers:dbservers' -m ping

# Exclude group
ansible 'all:!dbservers' -m ping

# Intersection
ansible 'webservers:&production' -m ping

# Single host
ansible web1.example.com -m ping

# Pattern matching
ansible 'web*.example.com' -m ping
ansible '192.168.1.*' -m ping
```

## Common Modules for Ad Hoc

| Module | Purpose |
|--------|---------|
| `ping` | Test connectivity |
| `command` | Run command (no shell) |
| `shell` | Run shell command |
| `copy` | Copy files |
| `file` | Manage files/directories |
| `yum/apt` | Package management |
| `service` | Service management |
| `user` | User management |
| `setup` | Gather facts |

See `adhoc-examples.sh` for comprehensive examples.
