# Core Components

## 1. Configuration Files (ansible.cfg)

Ansible searches for configuration files in this order:
1. `ANSIBLE_CONFIG` environment variable
2. `./ansible.cfg` (current directory)
3. `~/.ansible.cfg` (home directory)
4. `/etc/ansible/ansible.cfg` (system-wide)

### Check Current Configuration
```bash
# Show configuration file being used
ansible --version

# Show all configuration settings
ansible-config dump

# Show only changed settings
ansible-config dump --only-changed

# List all configuration options
ansible-config list
```

## 2. Facts

Facts are system variables collected from managed nodes.

### Gathering Facts
```bash
# Gather all facts
ansible all -m setup

# Filter specific facts
ansible all -m setup -a "filter=ansible_os_family"
ansible all -m setup -a "filter=ansible_distribution*"
ansible all -m setup -a "filter=ansible_memory_mb"
ansible all -m setup -a "filter=ansible_default_ipv4"
```

### Common Facts
| Fact | Description |
|------|-------------|
| `ansible_hostname` | System hostname |
| `ansible_fqdn` | Fully qualified domain name |
| `ansible_os_family` | OS family (RedHat, Debian, etc.) |
| `ansible_distribution` | Distribution name |
| `ansible_distribution_version` | Distribution version |
| `ansible_default_ipv4.address` | Primary IPv4 address |
| `ansible_memtotal_mb` | Total memory in MB |
| `ansible_processor_vcpus` | Number of vCPUs |

## 3. Inventory

Inventory defines managed hosts and how to connect to them.

### Inventory Formats
- **INI format** - Simple text format
- **YAML format** - More readable, supports complex structures
- **Dynamic inventory** - Scripts or plugins that generate inventory

## 4. Grouping and Parent-Child Relationships

Groups allow you to organize hosts logically:
- Apply variables to multiple hosts
- Target specific sets of hosts in playbooks
- Create nested group hierarchies

See the example files in this directory for detailed examples.
