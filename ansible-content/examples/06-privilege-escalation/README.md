# Privilege Escalation

## Overview

Privilege escalation allows Ansible to execute tasks with elevated privileges (like sudo or root).

## Configuration Methods

### 1. In ansible.cfg

```ini
[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

### 2. In Playbook

```yaml
- name: Playbook with privilege escalation
  hosts: all
  become: yes
  become_method: sudo
  become_user: root
```

### 3. At Task Level

```yaml
- name: Task requiring root
  yum:
    name: httpd
    state: present
  become: yes
```

### 4. Command Line

```bash
ansible-playbook playbook.yml --become
ansible-playbook playbook.yml -b --become-user=apache
ansible-playbook playbook.yml -b -K  # Ask for sudo password
```

## Become Methods

| Method | Description |
|--------|-------------|
| `sudo` | Default, uses sudo |
| `su` | Switch user |
| `pbrun` | PowerBroker |
| `pfexec` | Solaris privilege |
| `doas` | OpenBSD |
| `dzdo` | Centrify |
| `ksu` | Kerberos su |
| `runas` | Windows |

## Password Variables

| Variable | Description |
|----------|-------------|
| `ansible_password` | SSH password |
| `ansible_ssh_pass` | SSH password (alias) |
| `ansible_become_pass` | Sudo/become password |

## Best Practices

1. Use SSH keys instead of passwords
2. Configure passwordless sudo for ansible user
3. Use Ansible Vault for storing passwords
4. Limit sudo permissions when possible
5. Audit privilege escalation usage

See example files for detailed configurations.
