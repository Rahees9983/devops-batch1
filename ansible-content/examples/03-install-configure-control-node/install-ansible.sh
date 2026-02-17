#!/bin/bash
# Ansible Installation Script for Control Node
# Supports: RHEL/CentOS/Rocky, Ubuntu/Debian

set -e

echo "========================================="
echo "Ansible Control Node Installation Script"
echo "========================================="

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS $VERSION"

# Install based on OS
case $OS in
    rhel|centos|rocky|almalinux)
        echo "Installing on RHEL-based system..."

        # Enable EPEL
        sudo dnf install -y epel-release

        # Install Ansible
        sudo dnf install -y ansible-core python3-pip

        # Install additional packages
        sudo dnf install -y sshpass git
        ;;

    ubuntu|debian)
        echo "Installing on Debian-based system..."

        # Update package cache
        sudo apt update

        # Install prerequisites
        sudo apt install -y software-properties-common

        # Add Ansible PPA (Ubuntu only)
        if [ "$OS" == "ubuntu" ]; then
            sudo apt-add-repository -y ppa:ansible/ansible
            sudo apt update
        fi

        # Install Ansible
        sudo apt install -y ansible python3-pip sshpass git
        ;;

    *)
        echo "Using pip installation for unknown OS..."
        pip3 install ansible --user
        ;;
esac

# Install essential Python packages
pip3 install --user jmespath netaddr

# Install essential Ansible collections
echo "Installing essential collections..."
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

# Create Ansible directory structure
ANSIBLE_DIR="$HOME/ansible"
echo "Creating Ansible directory structure at $ANSIBLE_DIR..."

mkdir -p $ANSIBLE_DIR/{inventory/group_vars,inventory/host_vars,playbooks,roles,files,templates}

# Create default ansible.cfg
cat > $ANSIBLE_DIR/ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory/hosts
remote_user = ansible
host_key_checking = False
forks = 10
timeout = 30
stdout_callback = yaml
retry_files_enabled = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
EOF

# Create sample inventory
cat > $ANSIBLE_DIR/inventory/hosts << 'EOF'
# Ansible Inventory
[local]
localhost ansible_connection=local

[webservers]
# web1 ansible_host=192.168.1.101
# web2 ansible_host=192.168.1.102

[dbservers]
# db1 ansible_host=192.168.1.201

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Create group_vars/all.yml
cat > $ANSIBLE_DIR/inventory/group_vars/all.yml << 'EOF'
---
# Variables for all hosts
timezone: UTC
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
EOF

# Verify installation
echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
ansible --version
echo ""
echo "Ansible directory created at: $ANSIBLE_DIR"
echo "To get started:"
echo "  cd $ANSIBLE_DIR"
echo "  ansible all -m ping"
