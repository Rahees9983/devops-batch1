# Complete Ansible Guide

## Table of Contents
1. [Ansible Introduction](#ansible-introduction)
2. [Core Components](#core-components)
3. [Install and Configure Ansible Control Node](#install-and-configure-ansible-control-node)
4. [Configure Ansible Managed Nodes](#configure-ansible-managed-nodes)
5. [Ad Hoc Commands](#ad-hoc-commands)
6. [Privilege Escalation](#privilege-escalation)
7. [Ansible Playbook Run Options](#ansible-playbook-run-options)
8. [Ansible Modules](#ansible-modules)
9. [Variables and Jinja2](#variables-and-jinja2)
10. [Ansible Handlers](#ansible-handlers)
11. [Roles](#roles)
12. [Collections](#collections)
13. [Ansible Playbooks](#ansible-playbooks)
14. [Playbook Flow](#playbook-flow)
15. [Include and Roles](#include-and-roles)
16. [Ansible Vault](#ansible-vault)
17. [Dynamic Inventory](#dynamic-inventory)

---

## Ansible Introduction

### What is Ansible?
Ansible is an open-source IT automation tool that automates:
- **Configuration Management** - Managing system configurations consistently
- **Application Deployment** - Deploying applications across multiple servers
- **Task Automation** - Automating repetitive IT tasks
- **Orchestration** - Coordinating multi-tier deployments

### Key Features
- **Agentless** - No software needed on managed nodes (uses SSH)
- **Idempotent** - Running the same task multiple times produces the same result
- **Simple** - Uses YAML for playbooks (human-readable)
- **Extensible** - Custom modules and plugins can be created

### Architecture
```
┌─────────────────────┐
│   Control Node      │
│  (Ansible Installed)│
└─────────┬───────────┘
          │ SSH
          ▼
┌─────────────────────┐
│   Managed Nodes     │
│  (Target Servers)   │
└─────────────────────┘
```

---

## Core Components

### Configuration Files

Ansible uses a configuration file (`ansible.cfg`) to define default settings.

**Configuration File Search Order (Priority):**
1. `ANSIBLE_CONFIG` environment variable
2. `./ansible.cfg` (current directory)
3. `~/.ansible.cfg` (home directory)
4. `/etc/ansible/ansible.cfg` (system-wide)

**Example ansible.cfg:**
```ini
[defaults]
inventory = ./inventory
remote_user = ansible
ask_pass = false
host_key_checking = false
forks = 5
timeout = 30

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false
```

**Common Configuration Options:**
| Option | Description |
|--------|-------------|
| `inventory` | Path to inventory file |
| `remote_user` | SSH user for connections |
| `forks` | Number of parallel processes |
| `host_key_checking` | SSH host key verification |
| `timeout` | SSH connection timeout |
| `become` | Enable privilege escalation |
| `become_method` | Method for escalation (sudo, su) |

### Facts

Facts are system information gathered from managed nodes automatically.

**Gathering Facts:**
```bash
# View all facts
ansible all -m setup

# View specific fact
ansible all -m setup -a "filter=ansible_os_family"

# View memory facts
ansible all -m setup -a "filter=ansible_memory_mb"
```

**Common Facts:**
```yaml
ansible_hostname: webserver01
ansible_os_family: RedHat
ansible_distribution: CentOS
ansible_distribution_version: "8.5"
ansible_default_ipv4:
  address: 192.168.1.100
ansible_processor_cores: 4
ansible_memtotal_mb: 8192
```

**Using Facts in Playbooks:**
```yaml
---
- name: Display system information
  hosts: all
  tasks:
    - name: Show hostname and OS
      debug:
        msg: "Host {{ ansible_hostname }} runs {{ ansible_distribution }} {{ ansible_distribution_version }}"

    - name: Install package based on OS
      package:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"
```

**Disabling Fact Gathering:**
```yaml
---
- name: Playbook without fact gathering
  hosts: all
  gather_facts: no
  tasks:
    - name: Run command
      command: uptime
```

### Ansible Inventory

Inventory defines the managed hosts and how to connect to them.

**Default Inventory Location:** `/etc/ansible/hosts`

### Inventory Formats

**1. INI Format:**
```ini
# Simple hosts
web1.example.com
web2.example.com

# With connection variables
db1.example.com ansible_user=dbadmin ansible_port=2222

# Groups
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com

# Group variables
[webservers:vars]
http_port=80
max_clients=200
```

**2. YAML Format:**
```yaml
all:
  hosts:
    mail.example.com:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
      vars:
        http_port: 80
    dbservers:
      hosts:
        db1.example.com:
          ansible_user: dbadmin
        db2.example.com:
```

**3. Host Ranges:**
```ini
[webservers]
web[1:10].example.com      # web1 through web10
web[a:f].example.com       # weba through webf

[dbservers]
db-[01:03].example.com     # db-01, db-02, db-03
```

### Grouping and Parent-Child Relationships

**Nested Groups:**
```ini
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[production:children]
webservers
dbservers

[production:vars]
environment=prod
ntp_server=time.prod.example.com
```

**YAML Nested Groups:**
```yaml
all:
  children:
    production:
      children:
        webservers:
          hosts:
            web1.example.com:
            web2.example.com:
        dbservers:
          hosts:
            db1.example.com:
      vars:
        environment: prod
    staging:
      children:
        webservers:
          hosts:
            staging-web1.example.com:
```

**Special Groups:**
- `all` - Contains every host
- `ungrouped` - Hosts not in any group (except all)

---

## Install and Configure Ansible Control Node

### Install Required Packages

**On RHEL/CentOS/Rocky Linux:**
```bash
# Enable EPEL repository
sudo dnf install epel-release -y

# Install Ansible
sudo dnf install ansible-core -y

# Install additional collections
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
```

**On Ubuntu/Debian:**
```bash
# Add Ansible PPA
sudo apt-add-repository ppa:ansible/ansible
sudo apt update

# Install Ansible
sudo apt install ansible -y
```

**Using pip:**
```bash
# Install pip
sudo dnf install python3-pip -y

# Install Ansible
pip3 install ansible --user

# Verify installation
ansible --version
```

### Create a Static Host Inventory File

**Create inventory directory structure:**
```bash
mkdir -p ~/ansible/inventory
cd ~/ansible
```

**Create inventory file:**
```ini
# ~/ansible/inventory/hosts

[control]
localhost ansible_connection=local

[webservers]
web1 ansible_host=192.168.1.101
web2 ansible_host=192.168.1.102

[dbservers]
db1 ansible_host=192.168.1.201

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/ansible_key
```

**Verify inventory:**
```bash
# List all hosts
ansible-inventory --list -y

# Show specific group
ansible-inventory --graph webservers

# Ping all hosts
ansible all -m ping
```

### Create a Configuration File

**Create project-specific ansible.cfg:**
```ini
# ~/ansible/ansible.cfg

[defaults]
inventory = ./inventory/hosts
remote_user = ansible
private_key_file = ~/.ssh/ansible_key
host_key_checking = False
retry_files_enabled = False
forks = 10

# Logging
log_path = ./ansible.log

# Output
stdout_callback = yaml
callback_enabled = timer, profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

---

## Configure Ansible Managed Nodes

### Create and Distribute SSH Keys

**On Control Node:**
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""

# Copy public key to managed nodes
ssh-copy-id -i ~/.ssh/ansible_key.pub ansible@web1
ssh-copy-id -i ~/.ssh/ansible_key.pub ansible@web2
ssh-copy-id -i ~/.ssh/ansible_key.pub ansible@db1

# Test SSH connection
ssh -i ~/.ssh/ansible_key ansible@web1 "hostname"
```

**Using a script to distribute keys:**
```bash
#!/bin/bash
# distribute_keys.sh

SERVERS="web1 web2 db1"
KEY_FILE="~/.ssh/ansible_key.pub"

for server in $SERVERS; do
    echo "Copying key to $server..."
    ssh-copy-id -i $KEY_FILE ansible@$server
done
```

### Configure Privilege Escalation on Managed Nodes

**On each managed node:**
```bash
# Create ansible user
sudo useradd -m -s /bin/bash ansible

# Set password (optional)
echo "ansible:SecurePassword123" | sudo chpasswd

# Add to wheel/sudo group
sudo usermod -aG wheel ansible   # RHEL/CentOS
sudo usermod -aG sudo ansible    # Ubuntu/Debian

# Configure passwordless sudo
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible
sudo chmod 440 /etc/sudoers.d/ansible
```

**Validate sudoers configuration:**
```bash
sudo visudo -c -f /etc/sudoers.d/ansible
```

### Validate using Ad Hoc Commands

```bash
# Test connectivity
ansible all -m ping

# Test privilege escalation
ansible all -m command -a "whoami" --become

# Check sudo access
ansible all -m shell -a "sudo -l"

# Gather facts
ansible all -m setup -a "filter=ansible_distribution"
```

---

## Ad Hoc Commands

### Create Simple Shell Scripts That Run Ad Hoc Ansible Commands

**Basic Ad Hoc Command Syntax:**
```bash
ansible <host-pattern> -m <module> -a "<arguments>" [options]
```

**Examples:**
```bash
# Ping all hosts
ansible all -m ping

# Run command on webservers
ansible webservers -m command -a "uptime"

# Copy file to all hosts
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts"

# Install package
ansible webservers -m yum -a "name=httpd state=present" --become

# Start service
ansible webservers -m service -a "name=httpd state=started enabled=yes" --become

# Create user
ansible all -m user -a "name=deploy state=present" --become
```

**Shell Script for Common Tasks:**
```bash
#!/bin/bash
# ansible_admin.sh - Common Ansible administration tasks

# Configuration
INVENTORY="./inventory/hosts"

function check_connectivity() {
    echo "=== Checking connectivity ==="
    ansible all -i $INVENTORY -m ping
}

function system_info() {
    echo "=== System Information ==="
    ansible all -i $INVENTORY -m setup -a "filter=ansible_distribution*"
}

function disk_usage() {
    echo "=== Disk Usage ==="
    ansible all -i $INVENTORY -m shell -a "df -h"
}

function memory_usage() {
    echo "=== Memory Usage ==="
    ansible all -i $INVENTORY -m shell -a "free -m"
}

function update_packages() {
    echo "=== Updating Packages ==="
    ansible all -i $INVENTORY -m yum -a "name=* state=latest" --become
}

function restart_service() {
    SERVICE=$1
    echo "=== Restarting $SERVICE ==="
    ansible all -i $INVENTORY -m service -a "name=$SERVICE state=restarted" --become
}

# Main menu
case $1 in
    ping)     check_connectivity ;;
    info)     system_info ;;
    disk)     disk_usage ;;
    memory)   memory_usage ;;
    update)   update_packages ;;
    restart)  restart_service $2 ;;
    *)        echo "Usage: $0 {ping|info|disk|memory|update|restart <service>}" ;;
esac
```

---

## Privilege Escalation

### Understanding Privilege Escalation

Privilege escalation allows Ansible to execute tasks with elevated privileges (root).

**Methods:**
- `sudo` (default)
- `su`
- `pbrun`
- `pfexec`
- `doas`
- `dzdo`
- `ksu`
- `runas` (Windows)

**Configuration in ansible.cfg:**
```ini
[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

**In Playbooks:**
```yaml
---
- name: Playbook with privilege escalation
  hosts: all
  become: yes
  become_method: sudo
  become_user: root

  tasks:
    - name: Install package (requires root)
      yum:
        name: httpd
        state: present

    - name: Task as specific user
      command: whoami
      become_user: apache
      register: result

    - name: Task without escalation
      command: id
      become: no
```

**Ad Hoc with Privilege Escalation:**
```bash
# Using --become (-b)
ansible all -m yum -a "name=nginx state=present" --become

# Specify become user
ansible all -m command -a "whoami" --become --become-user=apache

# Ask for sudo password
ansible all -m command -a "whoami" --become --ask-become-pass
```

### ansible_ssh_pass or ansible_password

**Using Password Authentication:**

In inventory file:
```ini
[webservers]
web1 ansible_host=192.168.1.101 ansible_user=admin ansible_password=SecretPass123
web2 ansible_host=192.168.1.102 ansible_user=admin ansible_ssh_pass=SecretPass123
```

**Note:** `ansible_password` and `ansible_ssh_pass` are equivalent.

**Using Become Password:**
```ini
[webservers]
web1 ansible_host=192.168.1.101 ansible_become_pass=SudoPassword123
```

**Security Best Practices:**
```bash
# Use Ansible Vault for passwords
ansible-vault create secrets.yml

# Contents of secrets.yml
ansible_password: SecretPass123
ansible_become_pass: SudoPassword123
```

**Include encrypted vars:**
```yaml
---
- name: Playbook with vault
  hosts: webservers
  vars_files:
    - secrets.yml
  tasks:
    - name: Task requiring password
      command: echo "Hello"
```

---

## Ansible Playbook Run Options

### Check Mode or Dry Run

Check mode simulates playbook execution without making changes.

```bash
# Run in check mode
ansible-playbook playbook.yml --check

# Check mode with diff
ansible-playbook playbook.yml --check --diff
```

**In Playbooks:**
```yaml
---
- name: Playbook with check mode awareness
  hosts: all
  tasks:
    - name: Gather package facts (works in check mode)
      package_facts:
        manager: auto

    - name: Task that should run in check mode
      debug:
        msg: "This runs in check mode too"
      check_mode: no

    - name: Task that should NOT run in check mode
      shell: echo "Dangerous operation"
      when: not ansible_check_mode
```

### Start at Task

```bash
# Start at specific task
ansible-playbook playbook.yml --start-at-task="Install nginx"

# List all tasks
ansible-playbook playbook.yml --list-tasks

# Step through tasks interactively
ansible-playbook playbook.yml --step
```

### Tags

**Defining Tags:**
```yaml
---
- name: Web server setup
  hosts: webservers
  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present
      tags:
        - install
        - nginx

    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags:
        - configure
        - nginx

    - name: Start nginx
      service:
        name: nginx
        state: started
      tags:
        - service
        - nginx

    - name: Setup firewall
      firewalld:
        service: http
        permanent: yes
        state: enabled
      tags:
        - firewall
        - never  # Special tag - never runs unless explicitly called

    - name: Always run this
      debug:
        msg: "This always runs"
      tags:
        - always  # Special tag - always runs
```

**Running with Tags:**
```bash
# Run only tagged tasks
ansible-playbook playbook.yml --tags "install,configure"

# Skip specific tags
ansible-playbook playbook.yml --skip-tags "firewall"

# List all tags
ansible-playbook playbook.yml --list-tags

# Run 'never' tagged tasks
ansible-playbook playbook.yml --tags "firewall"
```

**Special Tags:**
- `always` - Task always runs unless explicitly skipped
- `never` - Task never runs unless explicitly tagged

---

## Ansible Modules

### Introduction to Ansible Modules

Modules are units of code that Ansible executes on managed nodes.

**Module Categories:**
- Cloud modules
- Clustering modules
- Commands modules
- Database modules
- Files modules
- Network modules
- Packaging modules
- System modules
- Windows modules

**Finding Module Documentation:**
```bash
# List all modules
ansible-doc -l

# Get module documentation
ansible-doc yum
ansible-doc copy

# Show module examples
ansible-doc -s copy
```

### Introduction to Ansible Plugins

Plugins extend Ansible's core functionality.

**Plugin Types:**
- **Action plugins** - Run on control node
- **Callback plugins** - Modify output
- **Connection plugins** - SSH, WinRM, etc.
- **Filter plugins** - Data manipulation in templates
- **Lookup plugins** - Retrieve data from external sources
- **Inventory plugins** - Dynamic inventory sources

**Example: Using Lookup Plugin**
```yaml
---
- name: Using lookup plugins
  hosts: localhost
  vars:
    file_content: "{{ lookup('file', '/etc/passwd') }}"
    env_var: "{{ lookup('env', 'HOME') }}"
    password: "{{ lookup('password', '/tmp/password length=12') }}"
  tasks:
    - debug:
        msg: "Home directory: {{ env_var }}"
```

### Modules and Plugin Index

**Documentation Resources:**
- Official docs: https://docs.ansible.com/ansible/latest/collections/
- Command line: `ansible-doc -l`

### Packages Module

**YUM/DNF (RHEL-based):**
```yaml
---
- name: Package management examples
  hosts: all
  become: yes
  tasks:
    - name: Install single package
      yum:
        name: httpd
        state: present

    - name: Install multiple packages
      yum:
        name:
          - nginx
          - vim
          - git
        state: present

    - name: Install specific version
      yum:
        name: httpd-2.4.6
        state: present

    - name: Update all packages
      yum:
        name: "*"
        state: latest

    - name: Remove package
      yum:
        name: httpd
        state: absent

    - name: Install from URL
      yum:
        name: https://example.com/package.rpm
        state: present
```

**APT (Debian-based):**
```yaml
---
- name: APT package management
  hosts: debian_servers
  become: yes
  tasks:
    - name: Update cache and install
      apt:
        name: nginx
        state: present
        update_cache: yes
        cache_valid_time: 3600

    - name: Install multiple packages
      apt:
        pkg:
          - nginx
          - vim
          - git
        state: present
```

**Generic Package Module:**
```yaml
---
- name: Cross-platform package management
  hosts: all
  become: yes
  tasks:
    - name: Install package (works on any OS)
      package:
        name: git
        state: present
```

### Services Module

```yaml
---
- name: Service management
  hosts: webservers
  become: yes
  tasks:
    - name: Start and enable service
      service:
        name: httpd
        state: started
        enabled: yes

    - name: Stop service
      service:
        name: httpd
        state: stopped

    - name: Restart service
      service:
        name: httpd
        state: restarted

    - name: Reload service
      service:
        name: httpd
        state: reloaded
```

**Using systemd module:**
```yaml
---
- name: Systemd service management
  hosts: all
  become: yes
  tasks:
    - name: Start service with systemd
      systemd:
        name: nginx
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Mask a service
      systemd:
        name: cups
        masked: yes
```

### File Content Modules

**Copy Module:**
```yaml
---
- name: File content management
  hosts: all
  become: yes
  tasks:
    - name: Copy file
      copy:
        src: /local/path/file.conf
        dest: /etc/app/file.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes

    - name: Copy with content
      copy:
        content: |
          # Configuration file
          setting1=value1
          setting2=value2
        dest: /etc/app/config.conf
        mode: '0644'
```

**File Module:**
```yaml
---
- name: File and directory management
  hosts: all
  become: yes
  tasks:
    - name: Create directory
      file:
        path: /opt/myapp
        state: directory
        owner: appuser
        group: appgroup
        mode: '0755'

    - name: Create symbolic link
      file:
        src: /opt/myapp/current
        dest: /opt/myapp/latest
        state: link

    - name: Delete file
      file:
        path: /tmp/oldfile.txt
        state: absent

    - name: Set file permissions
      file:
        path: /etc/app/config.conf
        owner: root
        group: wheel
        mode: '0640'
```

**Lineinfile Module:**
```yaml
---
- name: Manage lines in files
  hosts: all
  become: yes
  tasks:
    - name: Ensure line exists
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
        state: present

    - name: Add line after pattern
      lineinfile:
        path: /etc/hosts
        insertafter: '^127.0.0.1'
        line: '192.168.1.100 myserver.local'

    - name: Remove line
      lineinfile:
        path: /etc/hosts
        regexp: '^192.168.1.100'
        state: absent
```

**Blockinfile Module:**
```yaml
---
- name: Manage blocks in files
  hosts: all
  become: yes
  tasks:
    - name: Insert block of text
      blockinfile:
        path: /etc/ssh/sshd_config
        marker: "# {mark} ANSIBLE MANAGED BLOCK"
        block: |
          Match User deployer
            PasswordAuthentication no
            PubkeyAuthentication yes
```

### Archiving Module

```yaml
---
- name: Archive management
  hosts: all
  become: yes
  tasks:
    - name: Create tar.gz archive
      archive:
        path: /var/log/myapp
        dest: /backup/myapp-logs.tar.gz
        format: gz

    - name: Create archive of multiple paths
      archive:
        path:
          - /etc/myapp
          - /var/lib/myapp
        dest: /backup/myapp-full.tar.gz
        format: gz

    - name: Extract archive
      unarchive:
        src: /backup/myapp-full.tar.gz
        dest: /opt/restore/
        remote_src: yes

    - name: Download and extract
      unarchive:
        src: https://example.com/app.tar.gz
        dest: /opt/app/
        remote_src: yes
```

### Scheduled Tasks (Cron)

```yaml
---
- name: Cron job management
  hosts: all
  become: yes
  tasks:
    - name: Run backup script daily
      cron:
        name: "Daily backup"
        minute: "0"
        hour: "2"
        job: "/usr/local/bin/backup.sh >> /var/log/backup.log 2>&1"
        user: root

    - name: Run cleanup every 15 minutes
      cron:
        name: "Cleanup temp files"
        minute: "*/15"
        job: "find /tmp -type f -mtime +7 -delete"

    - name: Run weekly on Sunday
      cron:
        name: "Weekly report"
        minute: "0"
        hour: "8"
        weekday: "0"
        job: "/usr/local/bin/weekly-report.sh"

    - name: Remove cron job
      cron:
        name: "Old job"
        state: absent

    - name: Set cron environment variable
      cron:
        name: PATH
        env: yes
        value: "/usr/local/bin:/usr/bin:/bin"
```

**Using at for one-time tasks:**
```yaml
---
- name: Schedule one-time task
  hosts: all
  become: yes
  tasks:
    - name: Schedule reboot
      at:
        command: /sbin/reboot
        count: 5
        units: minutes
```

### Users and Groups

```yaml
---
- name: User and group management
  hosts: all
  become: yes
  tasks:
    # Group management
    - name: Create group
      group:
        name: developers
        gid: 2000
        state: present

    # User management
    - name: Create user
      user:
        name: john
        uid: 1001
        group: developers
        groups: wheel,docker
        shell: /bin/bash
        home: /home/john
        create_home: yes
        comment: "John Doe"
        state: present

    - name: Create user with SSH key
      user:
        name: deploy
        groups: developers
        generate_ssh_key: yes
        ssh_key_bits: 4096
        ssh_key_file: .ssh/id_rsa

    - name: Set user password
      user:
        name: john
        password: "{{ 'MyPassword123' | password_hash('sha512') }}"
        update_password: on_create

    - name: Remove user
      user:
        name: olduser
        state: absent
        remove: yes

    - name: Add SSH authorized key
      authorized_key:
        user: deploy
        key: "{{ lookup('file', '/path/to/public_key.pub') }}"
        state: present
```

---

## Variables and Jinja2

### Ansible Variables

Variables store values that can be reused throughout playbooks.

**Variable Naming Rules:**
- Must start with a letter
- Can contain letters, numbers, underscores
- Cannot use reserved words (like `environment`)

### Variable Types

**1. Simple Variables:**
```yaml
vars:
  http_port: 80
  app_name: "myapp"
  debug_mode: true
```

**2. List Variables:**
```yaml
vars:
  packages:
    - httpd
    - nginx
    - vim

# Usage
- name: Install packages
  yum:
    name: "{{ packages }}"
    state: present
```

**3. Dictionary Variables:**
```yaml
vars:
  user:
    name: john
    uid: 1001
    home: /home/john

# Usage
- name: Create user
  user:
    name: "{{ user.name }}"
    uid: "{{ user.uid }}"
    home: "{{ user.home }}"
```

### Variable Precedence

Variables can be defined in multiple places. Order (lowest to highest priority):

1. Command line values (lowest)
2. Role defaults (`defaults/main.yml`)
3. Inventory file or script group vars
4. Inventory `group_vars/all`
5. Playbook `group_vars/all`
6. Inventory `group_vars/*`
7. Playbook `group_vars/*`
8. Inventory file or script host vars
9. Inventory `host_vars/*`
10. Playbook `host_vars/*`
11. Host facts / cached set_facts
12. Play vars
13. Play vars_prompt
14. Play vars_files
15. Role vars (`vars/main.yml`)
16. Block vars
17. Task vars
18. include_vars
19. set_facts / registered vars
20. Role params
21. include params
22. Extra vars (`-e`) (highest)

**Example:**
```bash
# Extra vars override everything
ansible-playbook playbook.yml -e "http_port=8080"
```

### Variable Scope

**1. Global Scope:**
```yaml
# Set via command line or ansible.cfg
ansible-playbook playbook.yml -e "global_var=value"
```

**2. Play Scope:**
```yaml
---
- name: Play with scoped variables
  hosts: webservers
  vars:
    play_var: "visible to all tasks in this play"
```

**3. Host Scope:**
```yaml
# inventory/host_vars/web1.yml
host_specific_var: "only for web1"
```

### Use Variables to Retrieve the Results of Running Commands

```yaml
---
- name: Capture command output
  hosts: all
  tasks:
    - name: Get disk usage
      command: df -h /
      register: disk_result

    - name: Display disk usage
      debug:
        msg: "{{ disk_result.stdout }}"

    - name: Check if directory exists
      stat:
        path: /opt/myapp
      register: dir_stat

    - name: Create directory if missing
      file:
        path: /opt/myapp
        state: directory
      when: not dir_stat.stat.exists
```

### Variable Register

**Register Module Output:**
```yaml
---
- name: Using register
  hosts: all
  tasks:
    - name: Run command
      shell: cat /etc/passwd | wc -l
      register: user_count

    - name: Show registered variable
      debug:
        var: user_count

    - name: Use specific attributes
      debug:
        msg: |
          Return code: {{ user_count.rc }}
          Output: {{ user_count.stdout }}
          Errors: {{ user_count.stderr }}
          Changed: {{ user_count.changed }}
```

**Register with Loops:**
```yaml
---
- name: Register with loops
  hosts: all
  tasks:
    - name: Check multiple services
      service_facts:

    - name: Get status of specific services
      shell: "systemctl is-active {{ item }}"
      loop:
        - sshd
        - httpd
        - nginx
      register: service_status
      ignore_errors: yes

    - name: Display results
      debug:
        msg: "{{ item.item }}: {{ item.stdout }}"
      loop: "{{ service_status.results }}"
```

### Magic Variables

Ansible provides special variables automatically:

```yaml
---
- name: Using magic variables
  hosts: all
  tasks:
    - name: Show magic variables
      debug:
        msg: |
          Hostname: {{ inventory_hostname }}
          Short hostname: {{ inventory_hostname_short }}
          Groups: {{ group_names }}
          All hosts: {{ groups['all'] }}
          Webservers: {{ groups.webservers | default([]) }}
          Play hosts: {{ ansible_play_hosts }}
          Hostvars: {{ hostvars[inventory_hostname].ansible_default_ipv4.address }}
```

**Common Magic Variables:**
| Variable | Description |
|----------|-------------|
| `inventory_hostname` | Current host name from inventory |
| `inventory_hostname_short` | Short hostname |
| `group_names` | List of groups current host belongs to |
| `groups` | Dictionary of all groups and hosts |
| `hostvars` | Dictionary of all hosts and their variables |
| `ansible_play_hosts` | List of hosts in current play |
| `ansible_check_mode` | Boolean if running in check mode |

### Jinja2 Basics

Jinja2 is the templating engine used by Ansible.

**Syntax:**
- `{{ }}` - Output expressions
- `{% %}` - Control statements
- `{# #}` - Comments

**Examples:**
```jinja2
{# This is a comment #}

{# Variable output #}
Server name: {{ server_name }}

{# Conditional #}
{% if debug_mode %}
DEBUG=true
{% else %}
DEBUG=false
{% endif %}

{# Loop #}
{% for user in users %}
{{ user.name }}: {{ user.email }}
{% endfor %}

{# Filters #}
{{ name | upper }}
{{ list | join(', ') }}
{{ value | default('N/A') }}
```

### Jinja2 in Ansible

**Using Filters:**
```yaml
---
- name: Jinja2 filters
  hosts: localhost
  vars:
    users:
      - name: john
        admin: true
      - name: jane
        admin: false
  tasks:
    - debug:
        msg: |
          Upper: {{ 'hello' | upper }}
          Lower: {{ 'HELLO' | lower }}
          Default: {{ undefined_var | default('default_value') }}
          First: {{ users | first }}
          Length: {{ users | length }}
          JSON: {{ users | to_json }}
          YAML: {{ users | to_yaml }}
          Admins: {{ users | selectattr('admin', 'equalto', true) | list }}
```

**Common Filters:**
```yaml
# String filters
{{ name | upper }}
{{ name | lower }}
{{ name | capitalize }}
{{ name | replace('old', 'new') }}
{{ name | regex_replace('^www\.', '') }}

# List filters
{{ list | first }}
{{ list | last }}
{{ list | length }}
{{ list | sort }}
{{ list | unique }}
{{ list | join(', ') }}

# Dictionary filters
{{ dict | dict2items }}
{{ items | items2dict }}

# Math filters
{{ value | int }}
{{ value | float }}
{{ list | sum }}
{{ list | max }}
{{ list | min }}

# Path filters
{{ path | basename }}
{{ path | dirname }}
{{ path | expanduser }}

# Hash filters
{{ 'password' | password_hash('sha512') }}
{{ content | hash('md5') }}
```

### Create and Use Templates to Create Customized Configuration Files

**Template File (templates/nginx.conf.j2):**
```jinja2
# Nginx configuration - Generated by Ansible
# Do not edit manually

user {{ nginx_user }};
worker_processes {{ ansible_processor_vcpus }};

events {
    worker_connections {{ worker_connections | default(1024) }};
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    keepalive_timeout 65;

{% for server in virtual_hosts %}
    server {
        listen {{ server.port | default(80) }};
        server_name {{ server.name }};
        root {{ server.root }};

{% if server.ssl | default(false) %}
        ssl_certificate {{ server.ssl_cert }};
        ssl_certificate_key {{ server.ssl_key }};
{% endif %}

{% for location in server.locations | default([]) %}
        location {{ location.path }} {
            {{ location.config | indent(12) }}
        }
{% endfor %}
    }
{% endfor %}
}
```

**Playbook Using Template:**
```yaml
---
- name: Configure Nginx
  hosts: webservers
  become: yes
  vars:
    nginx_user: nginx
    worker_connections: 2048
    virtual_hosts:
      - name: example.com
        port: 80
        root: /var/www/example
        locations:
          - path: /
            config: |
              try_files $uri $uri/ =404;
          - path: /api
            config: |
              proxy_pass http://localhost:3000;
      - name: secure.example.com
        port: 443
        root: /var/www/secure
        ssl: true
        ssl_cert: /etc/ssl/certs/secure.crt
        ssl_key: /etc/ssl/private/secure.key

  tasks:
    - name: Deploy Nginx configuration
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        validate: nginx -t -c %s
      notify: Reload nginx

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

---

## Ansible Handlers

Handlers are special tasks that run only when notified.

**Basic Handler:**
```yaml
---
- name: Web server setup
  hosts: webservers
  become: yes

  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present
      notify: Start nginx

    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify:
        - Validate nginx
        - Reload nginx

  handlers:
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Validate nginx
      command: nginx -t
      changed_when: false

    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

**Handler Behavior:**
- Handlers run at the end of the play
- Each handler runs only once, even if notified multiple times
- Handlers run in the order they are defined, not the order notified

**Flushing Handlers:**
```yaml
---
- name: Flush handlers example
  hosts: webservers
  become: yes

  tasks:
    - name: Configure app
      template:
        src: app.conf.j2
        dest: /etc/app/app.conf
      notify: Restart app

    - name: Force handlers to run now
      meta: flush_handlers

    - name: Task that depends on app running
      uri:
        url: http://localhost:8080/health
        status_code: 200
```

**Listen Directive:**
```yaml
---
- name: Using listen
  hosts: webservers
  become: yes

  tasks:
    - name: Update SSL certificate
      copy:
        src: cert.pem
        dest: /etc/ssl/certs/app.pem
      notify: Restart web services

  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
      listen: Restart web services

    - name: Restart apache
      service:
        name: httpd
        state: restarted
      listen: Restart web services
```

---

## Roles

Roles provide a way to organize playbooks into reusable components.

### Role Directory Structure

```
roles/
└── webserver/
    ├── defaults/
    │   └── main.yml          # Default variables (lowest priority)
    ├── files/
    │   └── index.html        # Static files
    ├── handlers/
    │   └── main.yml          # Handlers
    ├── meta/
    │   └── main.yml          # Role metadata and dependencies
    ├── tasks/
    │   └── main.yml          # Main task list
    ├── templates/
    │   └── vhost.conf.j2     # Jinja2 templates
    ├── vars/
    │   └── main.yml          # Role variables (high priority)
    └── README.md             # Documentation
```

### Creating a Role

```bash
# Create role structure
ansible-galaxy init roles/webserver
```

**tasks/main.yml:**
```yaml
---
- name: Install web server packages
  yum:
    name: "{{ webserver_packages }}"
    state: present

- name: Deploy configuration
  template:
    src: vhost.conf.j2
    dest: "/etc/httpd/conf.d/{{ vhost_name }}.conf"
  notify: Restart httpd

- name: Deploy content
  copy:
    src: index.html
    dest: "{{ document_root }}/index.html"

- name: Start service
  service:
    name: httpd
    state: started
    enabled: yes
```

**defaults/main.yml:**
```yaml
---
webserver_packages:
  - httpd
  - mod_ssl
vhost_name: default
document_root: /var/www/html
http_port: 80
```

**handlers/main.yml:**
```yaml
---
- name: Restart httpd
  service:
    name: httpd
    state: restarted
```

**meta/main.yml:**
```yaml
---
galaxy_info:
  author: Your Name
  description: Web server role
  license: MIT
  min_ansible_version: "2.9"
  platforms:
    - name: EL
      versions:
        - "8"
        - "9"
  galaxy_tags:
    - webserver
    - httpd

dependencies:
  - role: common
  - role: firewall
    vars:
      firewall_ports:
        - 80
        - 443
```

### Using Roles

```yaml
---
- name: Deploy web servers
  hosts: webservers
  become: yes

  roles:
    - common
    - webserver
    - role: database
      vars:
        db_name: myapp
    - role: monitoring
      when: enable_monitoring | bool
```

**Using roles_path:**
```ini
# ansible.cfg
[defaults]
roles_path = ./roles:/etc/ansible/roles:~/.ansible/roles
```

### Installing Roles from Galaxy

```bash
# Install role
ansible-galaxy install geerlingguy.nginx

# Install from requirements file
ansible-galaxy install -r requirements.yml

# List installed roles
ansible-galaxy list
```

**requirements.yml:**
```yaml
---
roles:
  - name: geerlingguy.nginx
    version: "3.1.0"
  - name: geerlingguy.mysql
  - src: https://github.com/user/repo
    name: custom_role
    version: master
```

---

## Collections

Collections are a distribution format for Ansible content including roles, modules, plugins, and playbooks.

### Collection Structure

```
collection/
├── galaxy.yml              # Collection metadata
├── README.md
├── plugins/
│   ├── modules/
│   ├── inventory/
│   ├── lookup/
│   └── filter/
├── roles/
│   └── my_role/
├── playbooks/
│   └── deploy.yml
└── docs/
```

### Installing Collections

```bash
# Install from Galaxy
ansible-galaxy collection install community.general

# Install specific version
ansible-galaxy collection install community.general:5.0.0

# Install from requirements
ansible-galaxy collection install -r requirements.yml

# List installed collections
ansible-galaxy collection list
```

**requirements.yml:**
```yaml
---
collections:
  - name: community.general
    version: ">=5.0.0"
  - name: ansible.posix
  - name: community.mysql
  - name: https://github.com/org/collection/releases/download/1.0.0/org-collection-1.0.0.tar.gz
```

### Using Collections

```yaml
---
- name: Using collection modules
  hosts: all
  become: yes

  collections:
    - community.general
    - ansible.posix

  tasks:
    # Using FQCN (Fully Qualified Collection Name)
    - name: Install package
      ansible.builtin.yum:
        name: httpd
        state: present

    # Using collection module
    - name: Set timezone
      community.general.timezone:
        name: America/New_York

    # Using module from declared collection
    - name: Set file ACL
      acl:
        path: /etc/app
        entity: appuser
        etype: user
        permissions: rwx
        state: present
```

---

## Ansible Playbooks

### Playbook Structure

```yaml
---
# Play 1
- name: Configure web servers
  hosts: webservers
  become: yes
  gather_facts: yes

  vars:
    http_port: 80

  vars_files:
    - vars/main.yml

  pre_tasks:
    - name: Update cache
      yum:
        update_cache: yes

  roles:
    - common
    - webserver

  tasks:
    - name: Deploy application
      copy:
        src: app/
        dest: /var/www/html/

  post_tasks:
    - name: Verify deployment
      uri:
        url: "http://localhost:{{ http_port }}"
        status_code: 200

  handlers:
    - name: Restart httpd
      service:
        name: httpd
        state: restarted

# Play 2
- name: Configure database servers
  hosts: dbservers
  become: yes

  tasks:
    - name: Install MySQL
      yum:
        name: mysql-server
        state: present
```

### Verify Playbooks

```bash
# Syntax check
ansible-playbook playbook.yml --syntax-check

# List tasks
ansible-playbook playbook.yml --list-tasks

# List hosts
ansible-playbook playbook.yml --list-hosts

# Check mode (dry run)
ansible-playbook playbook.yml --check

# Diff mode (show changes)
ansible-playbook playbook.yml --check --diff

# Verbose output
ansible-playbook playbook.yml -v    # verbose
ansible-playbook playbook.yml -vv   # more verbose
ansible-playbook playbook.yml -vvv  # debug
ansible-playbook playbook.yml -vvvv # connection debug
```

**Using ansible-lint:**
```bash
# Install ansible-lint
pip install ansible-lint

# Lint playbook
ansible-lint playbook.yml

# Lint with specific rules
ansible-lint -r rules/ playbook.yml
```

---

## Playbook Flow

### Loops

**Simple Loop:**
```yaml
---
- name: Loop examples
  hosts: all
  become: yes
  tasks:
    - name: Install packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - httpd
        - nginx
        - vim
```

**Loop with Index:**
```yaml
    - name: Create numbered files
      file:
        path: "/tmp/file{{ index }}"
        state: touch
      loop: "{{ range(1, 6) | list }}"
      loop_control:
        index_var: index
```

**Loop over Dictionary:**
```yaml
    - name: Create users
      user:
        name: "{{ item.key }}"
        uid: "{{ item.value.uid }}"
        groups: "{{ item.value.groups }}"
      loop: "{{ users | dict2items }}"
      vars:
        users:
          john:
            uid: 1001
            groups: developers
          jane:
            uid: 1002
            groups: admins
```

**Nested Loops:**
```yaml
    - name: Grant database access
      mysql_user:
        name: "{{ item[0] }}"
        priv: "{{ item[1] }}.*:ALL"
        state: present
      loop: "{{ users | product(databases) | list }}"
      vars:
        users:
          - alice
          - bob
        databases:
          - app_db
          - analytics_db
```

**Loop Control:**
```yaml
    - name: Loop with control
      debug:
        msg: "Processing {{ item }}"
      loop:
        - item1
        - item2
        - item3
      loop_control:
        label: "{{ item }}"      # Custom label in output
        pause: 2                  # Pause between iterations
        index_var: idx           # Index variable name
        loop_var: current_item   # Loop variable name
```

### Use Conditionals to Control Play Execution

**When Conditional:**
```yaml
---
- name: Conditional examples
  hosts: all
  become: yes
  tasks:
    - name: Install on RedHat
      yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"

    - name: Install on Debian
      apt:
        name: apache2
        state: present
      when: ansible_os_family == "Debian"

    - name: Multiple conditions (AND)
      debug:
        msg: "CentOS 8 system"
      when:
        - ansible_distribution == "CentOS"
        - ansible_distribution_major_version == "8"

    - name: OR condition
      debug:
        msg: "RedHat-based system"
      when: ansible_distribution == "CentOS" or ansible_distribution == "RedHat"

    - name: Conditional with variable
      service:
        name: nginx
        state: started
      when: nginx_enabled | default(false) | bool

    - name: Check variable is defined
      debug:
        msg: "Variable is: {{ my_var }}"
      when: my_var is defined

    - name: Check if in list
      debug:
        msg: "This is a webserver"
      when: "'webservers' in group_names"
```

**Conditional with Register:**
```yaml
    - name: Check file exists
      stat:
        path: /etc/myapp/config.yml
      register: config_file

    - name: Create config if missing
      template:
        src: config.yml.j2
        dest: /etc/myapp/config.yml
      when: not config_file.stat.exists

    - name: Check command result
      command: /usr/bin/app --check
      register: app_check
      ignore_errors: yes

    - name: Fix app if check failed
      command: /usr/bin/app --repair
      when: app_check.rc != 0
```

### Blocks

Blocks group tasks and apply common attributes.

```yaml
---
- name: Block examples
  hosts: webservers
  become: yes
  tasks:
    - name: Web server setup
      block:
        - name: Install packages
          yum:
            name:
              - httpd
              - mod_ssl
            state: present

        - name: Configure httpd
          template:
            src: httpd.conf.j2
            dest: /etc/httpd/conf/httpd.conf

        - name: Start service
          service:
            name: httpd
            state: started
      when: ansible_os_family == "RedHat"
      become_user: root

    - name: Block with error handling
      block:
        - name: Risky operation
          command: /usr/bin/risky-command

        - name: Dependent operation
          command: /usr/bin/dependent-command

      rescue:
        - name: Handle failure
          debug:
            msg: "An error occurred, running recovery..."

        - name: Recovery command
          command: /usr/bin/recovery-command

      always:
        - name: Always run this
          debug:
            msg: "This runs regardless of success or failure"

        - name: Cleanup
          file:
            path: /tmp/lockfile
            state: absent
```

### Configure Error Handling

```yaml
---
- name: Error handling examples
  hosts: all
  tasks:
    # Ignore errors
    - name: Command that might fail
      command: /usr/bin/might-fail
      ignore_errors: yes

    # Ignore unreachable hosts
    - name: Task for potentially offline hosts
      ping:
      ignore_unreachable: yes

    # Custom failed condition
    - name: Check application status
      command: /usr/bin/app-status
      register: result
      failed_when: "'ERROR' in result.stdout"

    # Custom changed condition
    - name: Run script
      command: /usr/local/bin/script.sh
      register: script_result
      changed_when: "'CHANGED' in script_result.stdout"

    # any_errors_fatal - stop all hosts on first failure
    - name: Critical task
      command: /usr/bin/critical-command
      any_errors_fatal: yes

    # max_fail_percentage
    - name: Task with failure tolerance
      hosts: webservers
      max_fail_percentage: 25
      tasks:
        - name: Deploy application
          command: /usr/bin/deploy
```

**Force Handlers on Failure:**
```yaml
---
- name: Force handlers
  hosts: all
  force_handlers: yes

  tasks:
    - name: Configure app
      template:
        src: app.conf.j2
        dest: /etc/app/app.conf
      notify: Restart app

    - name: Task that might fail
      command: /usr/bin/might-fail

  handlers:
    - name: Restart app
      service:
        name: app
        state: restarted
```

### Manage Parallelism

**Serial Execution:**
```yaml
---
- name: Rolling update
  hosts: webservers
  serial: 2  # Process 2 hosts at a time
  become: yes

  tasks:
    - name: Disable in load balancer
      command: /usr/bin/disable-lb

    - name: Update application
      yum:
        name: myapp
        state: latest

    - name: Restart service
      service:
        name: myapp
        state: restarted

    - name: Enable in load balancer
      command: /usr/bin/enable-lb
```

**Serial with Percentage:**
```yaml
---
- name: Gradual rollout
  hosts: webservers
  serial:
    - 1          # First, 1 host
    - 5          # Then, 5 hosts
    - "25%"      # Then, 25% of remaining
  become: yes
```

**Throttle:**
```yaml
---
- name: API rate limiting
  hosts: all
  tasks:
    - name: Call external API
      uri:
        url: https://api.example.com/update
        method: POST
      throttle: 3  # Max 3 concurrent requests
```

**Forks:**
```bash
# In ansible.cfg
[defaults]
forks = 20

# Or command line
ansible-playbook playbook.yml -f 20
```

**Run Once:**
```yaml
---
- name: Database migration
  hosts: webservers
  tasks:
    - name: Run migration (only once)
      command: /usr/bin/migrate-db
      run_once: yes
      delegate_to: "{{ groups['dbservers'][0] }}"
```

---

## Include and Roles

### Ansible File Separation

**include_tasks:**
```yaml
---
# main.yml
- name: Main playbook
  hosts: all
  tasks:
    - name: Include common tasks
      include_tasks: tasks/common.yml

    - name: Include OS-specific tasks
      include_tasks: "tasks/{{ ansible_os_family }}.yml"

    - name: Conditional include
      include_tasks: tasks/setup.yml
      when: run_setup | bool
```

**import_tasks:**
```yaml
---
- name: Main playbook
  hosts: all
  tasks:
    # Static import - processed at parse time
    - import_tasks: tasks/always-needed.yml

    # With variables
    - import_tasks: tasks/user-setup.yml
      vars:
        username: deploy
```

**Include vs Import:**
| Feature | include_tasks | import_tasks |
|---------|---------------|--------------|
| Processing | Runtime (dynamic) | Parse time (static) |
| Conditionals | Applies to include itself | Applies to each task |
| Loops | Supported | Not supported |
| Tags | Cannot tag individual tasks | Can tag individual tasks |
| Handlers | Can notify handlers | Can notify handlers |

**include_vars:**
```yaml
---
- name: Include variables
  hosts: all
  tasks:
    - name: Include environment vars
      include_vars:
        file: "vars/{{ environment }}.yml"

    - name: Include all var files in directory
      include_vars:
        dir: vars/
        extensions:
          - yml
          - yaml
```

**import_playbook:**
```yaml
---
# site.yml
- import_playbook: webservers.yml
- import_playbook: dbservers.yml
- import_playbook: monitoring.yml
```

### Ansible Roles (include_role / import_role)

```yaml
---
- name: Using roles dynamically
  hosts: all
  tasks:
    - name: Apply base role
      include_role:
        name: common

    - name: Apply role with variables
      include_role:
        name: webserver
      vars:
        http_port: 8080

    - name: Conditional role
      include_role:
        name: monitoring
      when: enable_monitoring | bool

    - name: Apply specific tasks from role
      include_role:
        name: database
        tasks_from: backup.yml
```

**Static role import:**
```yaml
---
- name: Using import_role
  hosts: all
  tasks:
    - import_role:
        name: common
      tags:
        - common
        - base
```

---

## Ansible Vault

Ansible Vault encrypts sensitive data.

### Creating Encrypted Files

```bash
# Create new encrypted file
ansible-vault create secrets.yml

# Encrypt existing file
ansible-vault encrypt vars/passwords.yml

# View encrypted file
ansible-vault view secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Decrypt file
ansible-vault decrypt secrets.yml

# Re-key (change password)
ansible-vault rekey secrets.yml
```

### Encrypting Variables

```bash
# Encrypt single string
ansible-vault encrypt_string 'MySecretPassword' --name 'db_password'

# Output:
# db_password: !vault |
#           $ANSIBLE_VAULT;1.1;AES256
#           62313365396662343061393464336163...
```

**Using in playbooks:**
```yaml
---
- name: Using vault
  hosts: dbservers
  vars:
    db_user: myapp
    db_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          62313365396662343061393464336163383764313634363832...

  tasks:
    - name: Configure database
      mysql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        priv: '*.*:ALL'
```

### Running Playbooks with Vault

```bash
# Prompt for password
ansible-playbook playbook.yml --ask-vault-pass

# Use password file
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass

# Use environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
ansible-playbook playbook.yml

# Multiple vault passwords (vault IDs)
ansible-vault create --vault-id dev@prompt dev-secrets.yml
ansible-vault create --vault-id prod@~/.prod_vault_pass prod-secrets.yml

# Run with multiple vault IDs
ansible-playbook playbook.yml \
  --vault-id dev@prompt \
  --vault-id prod@~/.prod_vault_pass
```

### Best Practices

```yaml
# vars/main.yml (unencrypted)
db_user: myapp
db_host: localhost

# vars/vault.yml (encrypted)
vault_db_password: secretpassword

# Reference in playbook
db_password: "{{ vault_db_password }}"
```

---

## Dynamic Inventory

Dynamic inventory fetches host information from external sources.

### Inventory Plugins

**AWS EC2:**
```yaml
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
  - us-west-2
filters:
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
  - key: placement.availability_zone
    prefix: az
hostnames:
  - private-ip-address
compose:
  ansible_host: private_ip_address
```

**Azure:**
```yaml
# inventory/azure_rm.yml
plugin: azure.azcollection.azure_rm
auth_source: auto
include_vm_resource_groups:
  - production-rg
keyed_groups:
  - prefix: tag
    key: tags
```

**GCP:**
```yaml
# inventory/gcp_compute.yml
plugin: google.cloud.gcp_compute
projects:
  - my-project-id
zones:
  - us-central1-a
filters:
  - status = RUNNING
keyed_groups:
  - key: labels.environment
    prefix: env
```

### Custom Dynamic Inventory Script

```python
#!/usr/bin/env python3
# inventory/custom_inventory.py

import json
import argparse

def get_inventory():
    return {
        "webservers": {
            "hosts": ["web1.example.com", "web2.example.com"],
            "vars": {
                "http_port": 80
            }
        },
        "dbservers": {
            "hosts": ["db1.example.com"]
        },
        "_meta": {
            "hostvars": {
                "web1.example.com": {
                    "ansible_host": "192.168.1.101"
                },
                "web2.example.com": {
                    "ansible_host": "192.168.1.102"
                },
                "db1.example.com": {
                    "ansible_host": "192.168.1.201"
                }
            }
        }
    }

def get_host(hostname):
    inventory = get_inventory()
    return inventory.get("_meta", {}).get("hostvars", {}).get(hostname, {})

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--host", type=str)
    args = parser.parse_args()

    if args.list:
        print(json.dumps(get_inventory(), indent=2))
    elif args.host:
        print(json.dumps(get_host(args.host), indent=2))
```

**Make script executable:**
```bash
chmod +x inventory/custom_inventory.py

# Test script
./inventory/custom_inventory.py --list

# Use with ansible
ansible-inventory -i inventory/custom_inventory.py --list
ansible all -i inventory/custom_inventory.py -m ping
```

### Combining Static and Dynamic Inventory

```ini
# ansible.cfg
[defaults]
inventory = ./inventory/
```

```
inventory/
├── 01-static.yml          # Static hosts
├── 02-aws_ec2.yml         # AWS dynamic
├── group_vars/
│   ├── all.yml
│   └── webservers.yml
└── host_vars/
    └── special-host.yml
```

**Verify combined inventory:**
```bash
ansible-inventory --list
ansible-inventory --graph
```

---

## Quick Reference

### Common Commands

```bash
# Playbook execution
ansible-playbook playbook.yml
ansible-playbook playbook.yml -i inventory
ansible-playbook playbook.yml -l webservers
ansible-playbook playbook.yml --check --diff
ansible-playbook playbook.yml --tags "install,configure"
ansible-playbook playbook.yml -e "var=value"

# Ad hoc commands
ansible all -m ping
ansible webservers -m shell -a "uptime"
ansible all -m setup -a "filter=ansible_distribution"

# Inventory
ansible-inventory --list
ansible-inventory --graph

# Vault
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
ansible-vault encrypt_string 'secret' --name 'var_name'

# Galaxy
ansible-galaxy init role_name
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install community.general

# Documentation
ansible-doc module_name
ansible-doc -l | grep keyword
```

### File Locations

| Item | Default Location |
|------|------------------|
| Configuration | `/etc/ansible/ansible.cfg`, `~/.ansible.cfg`, `./ansible.cfg` |
| Inventory | `/etc/ansible/hosts` |
| Roles | `/etc/ansible/roles`, `~/.ansible/roles`, `./roles` |
| Collections | `~/.ansible/collections` |
| Plugins | `/usr/share/ansible/plugins` |

---

*This guide covers Ansible fundamentals through advanced topics. For the most current information, refer to the official Ansible documentation at https://docs.ansible.com/*
