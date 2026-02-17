# Install and Configure Ansible Control Node

## Prerequisites

- Python 3.8 or later
- SSH client
- Supported OS: RHEL, CentOS, Rocky Linux, Ubuntu, Debian, macOS

## Installation Methods

### 1. RHEL/CentOS/Rocky Linux

```bash
# Enable EPEL repository
sudo dnf install epel-release -y

# Install Ansible Core
sudo dnf install ansible-core -y

# Or install full Ansible package
sudo dnf install ansible -y
```

### 2. Ubuntu/Debian

```bash
# Add Ansible PPA
sudo apt-add-repository ppa:ansible/ansible
sudo apt update

# Install Ansible
sudo apt install ansible -y
```

### 3. Using pip (All platforms)

```bash
# Install pip if not present
sudo dnf install python3-pip -y  # RHEL
sudo apt install python3-pip -y   # Ubuntu

# Install Ansible
pip3 install ansible --user

# Install specific version
pip3 install ansible==8.0.0 --user

# Upgrade Ansible
pip3 install ansible --upgrade --user
```

### 4. macOS

```bash
# Using Homebrew
brew install ansible

# Using pip
pip3 install ansible
```

## Verify Installation

```bash
# Check Ansible version
ansible --version

# Check installed collections
ansible-galaxy collection list

# Check Python interpreter
ansible --version | grep python
```

## Directory Structure

```
~/ansible/
├── ansible.cfg          # Project configuration
├── inventory/
│   ├── hosts            # Static inventory
│   ├── group_vars/
│   │   ├── all.yml      # Variables for all hosts
│   │   └── webservers.yml
│   └── host_vars/
│       └── web1.yml
├── playbooks/
├── roles/
└── files/
```

## Essential Collections

```bash
# Install commonly used collections
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
ansible-galaxy collection install community.mysql
ansible-galaxy collection install community.postgresql
```

See the example files for complete setup scripts and configurations.
