#!/bin/bash
# Ansible Ad Hoc Command Examples
# These commands demonstrate various ad hoc operations

#=============================================
# CONNECTIVITY & INFORMATION
#=============================================

# Test connectivity to all hosts
ansible all -m ping

# Test connectivity with verbose output
ansible all -m ping -v

# Gather all facts from hosts
ansible all -m setup

# Gather specific facts
ansible all -m setup -a "filter=ansible_distribution*"
ansible all -m setup -a "filter=ansible_memory_mb"
ansible all -m setup -a "filter=ansible_default_ipv4"

#=============================================
# COMMAND EXECUTION
#=============================================

# Run a simple command
ansible all -m command -a "uptime"

# Run command with arguments
ansible all -m command -a "df -h /"

# Run shell command (supports pipes, redirects)
ansible all -m shell -a "ps aux | grep nginx | wc -l"

# Run command and capture output
ansible all -m shell -a "cat /etc/os-release | head -5"

# Run command as root
ansible all -m command -a "cat /etc/shadow" --become

# Run command as specific user
ansible all -m command -a "whoami" --become --become-user=apache

#=============================================
# FILE OPERATIONS
#=============================================

# Copy file to remote hosts
ansible all -m copy -a "src=/local/file.txt dest=/tmp/file.txt mode=0644"

# Copy with content
ansible all -m copy -a "content='Hello World\n' dest=/tmp/hello.txt"

# Create directory
ansible all -m file -a "path=/opt/myapp state=directory mode=0755" --become

# Create symbolic link
ansible all -m file -a "src=/opt/myapp/current dest=/opt/myapp/latest state=link" --become

# Delete file
ansible all -m file -a "path=/tmp/unwanted.txt state=absent"

# Change file permissions
ansible all -m file -a "path=/etc/config.conf mode=0600 owner=root group=root" --become

# Fetch file from remote
ansible all -m fetch -a "src=/var/log/messages dest=/tmp/logs/ flat=yes"

#=============================================
# PACKAGE MANAGEMENT
#=============================================

# Install package (RedHat)
ansible webservers -m yum -a "name=httpd state=present" --become

# Install package (Debian)
ansible webservers -m apt -a "name=apache2 state=present update_cache=yes" --become

# Install multiple packages
ansible all -m yum -a "name=vim,wget,curl state=present" --become

# Remove package
ansible all -m yum -a "name=telnet state=absent" --become

# Update all packages
ansible all -m yum -a "name=* state=latest" --become

# Cross-platform package install
ansible all -m package -a "name=git state=present" --become

#=============================================
# SERVICE MANAGEMENT
#=============================================

# Start service
ansible webservers -m service -a "name=httpd state=started" --become

# Stop service
ansible webservers -m service -a "name=httpd state=stopped" --become

# Restart service
ansible webservers -m service -a "name=httpd state=restarted" --become

# Enable service at boot
ansible webservers -m service -a "name=httpd enabled=yes" --become

# Check service status
ansible all -m shell -a "systemctl status httpd" --become

#=============================================
# USER MANAGEMENT
#=============================================

# Create user
ansible all -m user -a "name=deploy state=present shell=/bin/bash" --become

# Create user with specific UID
ansible all -m user -a "name=appuser uid=2001 group=wheel" --become

# Remove user
ansible all -m user -a "name=olduser state=absent remove=yes" --become

# Add SSH key for user
ansible all -m authorized_key -a "user=deploy key='ssh-rsa AAAA...' state=present" --become

# Create group
ansible all -m group -a "name=developers gid=3000 state=present" --become

#=============================================
# CRON JOBS
#=============================================

# Create cron job
ansible all -m cron -a "name='Daily backup' hour=2 minute=0 job='/usr/local/bin/backup.sh'" --become

# Remove cron job
ansible all -m cron -a "name='Daily backup' state=absent" --become

#=============================================
# FIREWALL
#=============================================

# Allow HTTP (firewalld)
ansible all -m firewalld -a "service=http permanent=yes state=enabled" --become

# Allow port (firewalld)
ansible all -m firewalld -a "port=8080/tcp permanent=yes state=enabled" --become

#=============================================
# DISK & FILESYSTEM
#=============================================

# Get disk usage
ansible all -m shell -a "df -h"

# Get memory usage
ansible all -m shell -a "free -m"

# Mount filesystem
ansible all -m mount -a "path=/mnt/data src=/dev/sdb1 fstype=ext4 state=mounted" --become

#=============================================
# LIMITING EXECUTION
#=============================================

# Run on specific host
ansible all -m ping --limit "web1.example.com"

# Run on multiple hosts
ansible all -m ping --limit "web1.example.com,web2.example.com"

# Run on first host only
ansible all -m ping --limit "webservers[0]"

# Dry run (check mode)
ansible all -m yum -a "name=httpd state=present" --become --check

#=============================================
# PARALLEL EXECUTION
#=============================================

# Change number of parallel processes
ansible all -m ping -f 20

# Serial execution (one at a time)
ansible all -m ping -f 1

#=============================================
# OUTPUT FORMATS
#=============================================

# One-line output
ansible all -m ping -o

# Tree format
ansible all -m ping --tree /tmp/ansible_output

# JSON output
ANSIBLE_STDOUT_CALLBACK=json ansible all -m ping
