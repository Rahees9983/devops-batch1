# Configure Ansible Managed Nodes

## Prerequisites on Managed Nodes

1. SSH server installed and running
2. Python 3 installed
3. User account for Ansible
4. Sudo/root access configured

## Setup Steps

### 1. Create Ansible User

```bash
# On each managed node
sudo useradd -m -s /bin/bash ansible
echo "ansible:SecurePassword123" | sudo chpasswd  # Optional
```

### 2. Configure SSH Key Authentication

```bash
# On control node - Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""

# Copy public key to managed nodes
ssh-copy-id -i ~/.ssh/ansible_key.pub ansible@managed-node

# Or manually copy key
cat ~/.ssh/ansible_key.pub | ssh user@managed-node "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Configure Passwordless Sudo

```bash
# On managed node - Add sudoers entry
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible
sudo chmod 440 /etc/sudoers.d/ansible
```

### 4. Validate Connection

```bash
# Test SSH connection
ssh -i ~/.ssh/ansible_key ansible@managed-node

# Test with Ansible
ansible all -m ping
ansible all -m command -a "whoami" --become
```

## Security Best Practices

1. Use SSH key authentication (disable password auth)
2. Limit sudo permissions to specific commands if possible
3. Use separate ansible user (not root)
4. Implement SSH hardening
5. Use Ansible Vault for sensitive data

See the example scripts and playbooks in this directory.
