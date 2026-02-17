#!/bin/bash
# Script to configure a managed node for Ansible
# Run this script ON the managed node (not control node)

set -e

ANSIBLE_USER="ansible"
ANSIBLE_GROUP="ansible"

echo "========================================="
echo "Ansible Managed Node Configuration"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS"

# Install prerequisites
echo "Installing prerequisites..."
case $OS in
    rhel|centos|rocky|almalinux)
        dnf install -y python3 openssh-server sudo
        systemctl enable sshd
        systemctl start sshd
        ;;
    ubuntu|debian)
        apt update
        apt install -y python3 openssh-server sudo
        systemctl enable ssh
        systemctl start ssh
        ;;
esac

# Create ansible user
echo "Creating ansible user..."
if id "$ANSIBLE_USER" &>/dev/null; then
    echo "User $ANSIBLE_USER already exists"
else
    useradd -m -s /bin/bash $ANSIBLE_USER
    echo "User $ANSIBLE_USER created"
fi

# Create .ssh directory
echo "Setting up SSH directory..."
ANSIBLE_HOME=$(getent passwd $ANSIBLE_USER | cut -d: -f6)
mkdir -p $ANSIBLE_HOME/.ssh
chmod 700 $ANSIBLE_HOME/.ssh
touch $ANSIBLE_HOME/.ssh/authorized_keys
chmod 600 $ANSIBLE_HOME/.ssh/authorized_keys
chown -R $ANSIBLE_USER:$ANSIBLE_USER $ANSIBLE_HOME/.ssh

# Configure sudo
echo "Configuring passwordless sudo..."
cat > /etc/sudoers.d/ansible << EOF
# Ansible sudo configuration
$ANSIBLE_USER ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers.d/ansible

# Validate sudoers file
visudo -c -f /etc/sudoers.d/ansible

# Configure SSH (optional hardening)
echo "Configuring SSH..."
# Backup original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Ensure key-based auth is enabled
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
case $OS in
    rhel|centos|rocky|almalinux)
        systemctl restart sshd
        ;;
    ubuntu|debian)
        systemctl restart ssh
        ;;
esac

echo ""
echo "========================================="
echo "Managed Node Configuration Complete!"
echo "========================================="
echo ""
echo "Next steps on CONTROL NODE:"
echo "1. Generate SSH key (if not exists):"
echo "   ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ''"
echo ""
echo "2. Copy public key to this node:"
echo "   ssh-copy-id -i ~/.ssh/ansible_key.pub $ANSIBLE_USER@$(hostname -I | awk '{print $1}')"
echo ""
echo "3. Test connection:"
echo "   ssh -i ~/.ssh/ansible_key $ANSIBLE_USER@$(hostname -I | awk '{print $1}')"
echo ""
echo "4. Test Ansible:"
echo "   ansible all -m ping"
