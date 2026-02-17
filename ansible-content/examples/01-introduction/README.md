# Ansible Introduction

## What is Ansible?

Ansible is an open-source IT automation engine that automates:
- **Provisioning** - Setting up servers and infrastructure
- **Configuration Management** - Managing system configurations
- **Application Deployment** - Deploying applications
- **Orchestration** - Coordinating multi-tier deployments
- **Security & Compliance** - Applying security policies

## Key Features

| Feature | Description |
|---------|-------------|
| **Agentless** | No software needed on managed nodes (uses SSH/WinRM) |
| **Idempotent** | Running same task multiple times = same result |
| **Simple** | Uses YAML (human-readable) |
| **Extensible** | Custom modules, plugins, and roles |
| **Secure** | Uses SSH, supports Vault for secrets |

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                      CONTROL NODE                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Playbook │  │ Inventory│  │  Modules │  │  Plugins │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                         │                                  │
│                    ansible.cfg                             │
└─────────────────────────┬──────────────────────────────────┘
                          │
                          │ SSH / WinRM
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Managed Node │  │ Managed Node │  │ Managed Node │
│   (Linux)    │  │   (Linux)    │  │  (Windows)   │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Ansible vs Other Tools

| Feature | Ansible | Puppet | Chef | SaltStack |
|---------|---------|--------|------|-----------|
| Architecture | Agentless | Agent-based | Agent-based | Agent or Agentless |
| Language | YAML | Puppet DSL | Ruby | YAML/Python |
| Push/Pull | Push | Pull | Pull | Both |
| Learning Curve | Easy | Medium | Hard | Medium |

## Basic Terminology

- **Control Node**: Machine where Ansible is installed
- **Managed Node**: Target machines managed by Ansible
- **Inventory**: List of managed nodes
- **Playbook**: YAML file containing tasks
- **Task**: Single unit of work
- **Module**: Reusable code unit (e.g., yum, copy, service)
- **Role**: Collection of playbooks, tasks, handlers
- **Facts**: System information gathered from nodes

## First Commands

```bash
# Check Ansible version
ansible --version

# Ping all hosts in inventory
ansible all -m ping

# Run command on all hosts
ansible all -m command -a "uptime"

# Gather facts from a host
ansible web1 -m setup
```

## Directory Structure Best Practice

```
ansible-project/
├── ansible.cfg              # Configuration file
├── inventory/
│   ├── production           # Production hosts
│   ├── staging              # Staging hosts
│   └── group_vars/
│       └── all.yml          # Variables for all groups
├── playbooks/
│   ├── site.yml             # Main playbook
│   └── webservers.yml       # Webserver playbook
├── roles/
│   └── common/              # Common role
└── files/                   # Static files
```

## Running Your First Playbook

See `first-playbook.yml` in this directory.

```bash
# Syntax check
ansible-playbook first-playbook.yml --syntax-check

# Dry run
ansible-playbook first-playbook.yml --check

# Run playbook
ansible-playbook first-playbook.yml
```
