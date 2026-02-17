# Dynamic Inventory

## Overview

Dynamic inventory fetches host information from external sources at runtime instead of using static files.

## Types of Dynamic Inventory

1. **Inventory Plugins** - Built-in or from collections
2. **Inventory Scripts** - Custom Python/Shell scripts

## Inventory Plugins

### AWS EC2

```yaml
# aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
```

### Azure

```yaml
# azure_rm.yml
plugin: azure.azcollection.azure_rm
auth_source: auto
include_vm_resource_groups:
  - production-rg
```

### GCP

```yaml
# gcp_compute.yml
plugin: google.cloud.gcp_compute
projects:
  - my-project
zones:
  - us-central1-a
```

## Inventory Script Interface

Scripts must support:
- `--list`: Return all groups and hosts as JSON
- `--host <hostname>`: Return host variables as JSON

## Testing Dynamic Inventory

```bash
# Test inventory plugin/script
ansible-inventory -i inventory.yml --list

# Show graph
ansible-inventory -i inventory.yml --graph

# Test ping
ansible all -i inventory.yml -m ping
```

## Combining Inventories

```bash
# Point to directory containing multiple inventory sources
ansible-playbook -i inventory/ playbook.yml
```

See example files for implementation details.
