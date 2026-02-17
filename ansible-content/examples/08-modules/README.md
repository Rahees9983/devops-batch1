# Ansible Modules

## What are Modules?

Modules are units of code that Ansible executes on managed nodes. They are the building blocks of Ansible automation.

## Module Documentation

```bash
# List all modules
ansible-doc -l

# Search for modules
ansible-doc -l | grep "package"

# View module documentation
ansible-doc yum
ansible-doc copy
ansible-doc service

# Show module examples
ansible-doc -s yum
```

## Module Categories

| Category | Examples |
|----------|----------|
| Packages | yum, apt, dnf, pip, package |
| Services | service, systemd |
| Files | file, copy, template, lineinfile |
| Archives | archive, unarchive |
| Scheduled Tasks | cron, at |
| Users/Groups | user, group, authorized_key |
| Commands | command, shell, raw, script |
| Network | uri, get_url, firewalld |
| Database | mysql_db, postgresql_db |
| Cloud | ec2, azure_rm, gcp_compute |

## Plugins

Plugins extend Ansible's core functionality:

| Type | Purpose |
|------|---------|
| Action | Modify module behavior |
| Callback | Custom output formatting |
| Connection | SSH, WinRM, Docker, etc. |
| Filter | Data manipulation |
| Lookup | External data retrieval |
| Inventory | Dynamic inventory sources |

## Directory Structure

This directory contains examples for:
- `packages/` - Package management
- `services/` - Service management
- `files/` - File operations
- `archives/` - Archive handling
- `cron/` - Scheduled tasks
- `users-groups/` - User management

See subdirectories for detailed examples.
