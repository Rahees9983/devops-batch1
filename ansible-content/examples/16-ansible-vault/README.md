# Ansible Vault

## Overview

Ansible Vault encrypts sensitive data like passwords, keys, and other secrets.

## Basic Commands

```bash
# Create encrypted file
ansible-vault create secrets.yml

# View encrypted file
ansible-vault view secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Encrypt existing file
ansible-vault encrypt vars/passwords.yml

# Decrypt file
ansible-vault decrypt secrets.yml

# Re-key (change password)
ansible-vault rekey secrets.yml
```

## Encrypt String

```bash
# Encrypt single value
ansible-vault encrypt_string 'supersecret' --name 'db_password'

# Output:
# db_password: !vault |
#   $ANSIBLE_VAULT;1.1;AES256
#   61626364...
```

## Running Playbooks with Vault

```bash
# Prompt for password
ansible-playbook playbook.yml --ask-vault-pass

# Use password file
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass

# Environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
ansible-playbook playbook.yml
```

## Vault IDs (Multiple Passwords)

```bash
# Create with vault ID
ansible-vault create --vault-id dev@prompt dev-secrets.yml
ansible-vault create --vault-id prod@~/.prod_pass prod-secrets.yml

# Run with multiple vault IDs
ansible-playbook playbook.yml \
  --vault-id dev@prompt \
  --vault-id prod@~/.prod_pass
```

## Best Practices

1. Never commit vault passwords to version control
2. Use separate vault files for different environments
3. Use `vault_` prefix for encrypted variable names
4. Store vault password file with restricted permissions
5. Use vault IDs for multiple environments

See example files for detailed usage.
