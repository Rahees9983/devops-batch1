#!/bin/bash
# Script to distribute SSH keys to managed nodes
# Run this script on the CONTROL NODE

SSH_KEY_PATH="$HOME/.ssh/ansible_key"
SSH_PUB_KEY_PATH="${SSH_KEY_PATH}.pub"
ANSIBLE_USER="ansible"

# List of managed nodes - modify as needed
MANAGED_NODES=(
    "192.168.1.101"
    "192.168.1.102"
    "192.168.1.201"
)

echo "========================================="
echo "SSH Key Distribution Script"
echo "========================================="

# Check if SSH key exists, create if not
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "SSH key not found. Generating new key pair..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
    echo "SSH key generated at $SSH_KEY_PATH"
fi

echo "Public key:"
cat "$SSH_PUB_KEY_PATH"
echo ""

# Function to copy key to a single host
copy_key_to_host() {
    local host=$1
    echo "----------------------------------------"
    echo "Copying key to $ANSIBLE_USER@$host..."

    # Try ssh-copy-id first
    if ssh-copy-id -i "$SSH_PUB_KEY_PATH" -o StrictHostKeyChecking=no "$ANSIBLE_USER@$host" 2>/dev/null; then
        echo "SUCCESS: Key copied to $host"
    else
        echo "FAILED: Could not copy key to $host"
        echo "You may need to manually copy the key or check connectivity"
    fi
}

# Copy keys to all managed nodes
for node in "${MANAGED_NODES[@]}"; do
    copy_key_to_host "$node"
done

echo ""
echo "========================================="
echo "Key Distribution Complete"
echo "========================================="
echo ""
echo "Test connections with:"
for node in "${MANAGED_NODES[@]}"; do
    echo "  ssh -i $SSH_KEY_PATH $ANSIBLE_USER@$node"
done
echo ""
echo "Test with Ansible:"
echo "  ansible all -m ping"
