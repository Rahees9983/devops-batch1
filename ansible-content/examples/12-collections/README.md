# Ansible Collections

## What are Collections?

Collections are a distribution format for Ansible content that includes roles, modules, plugins, and playbooks in a single package.

## Collection Structure

```
namespace/
└── collection_name/
    ├── galaxy.yml          # Collection metadata
    ├── README.md
    ├── plugins/
    │   ├── modules/        # Custom modules
    │   ├── inventory/      # Inventory plugins
    │   ├── lookup/         # Lookup plugins
    │   └── filter/         # Filter plugins
    ├── roles/
    │   └── my_role/
    ├── playbooks/
    │   └── deploy.yml
    └── docs/
```

## Installing Collections

```bash
# From Galaxy
ansible-galaxy collection install community.general

# Specific version
ansible-galaxy collection install community.general:5.0.0

# From requirements file
ansible-galaxy collection install -r requirements.yml

# From tarball
ansible-galaxy collection install ./my_collection-1.0.0.tar.gz
```

## Using Collections

```yaml
# Method 1: FQCN (Fully Qualified Collection Name)
- name: Use collection module
  community.general.timezone:
    name: America/New_York

# Method 2: collections keyword
- hosts: all
  collections:
    - community.general

  tasks:
    - name: Use module without FQCN
      timezone:
        name: America/New_York
```

## Common Collections

| Collection | Description |
|------------|-------------|
| `ansible.builtin` | Core Ansible modules |
| `ansible.posix` | POSIX system modules |
| `community.general` | General purpose modules |
| `community.mysql` | MySQL modules |
| `community.docker` | Docker modules |
| `amazon.aws` | AWS modules |
| `azure.azcollection` | Azure modules |

See example files for detailed usage.
