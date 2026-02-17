# Ansible Playbooks

## What is a Playbook?

A playbook is a YAML file containing one or more plays that define automation tasks to execute on managed hosts.

## Playbook Structure

```yaml
---
# Play 1
- name: Configure web servers
  hosts: webservers
  become: yes

  vars:
    http_port: 80

  pre_tasks:
    - name: Update cache
      package:
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
        url: http://localhost/

  handlers:
    - name: Restart service
      service:
        name: httpd
        state: restarted

# Play 2
- name: Configure database
  hosts: dbservers
  tasks: ...
```

## Running Playbooks

```bash
# Basic execution
ansible-playbook playbook.yml

# With inventory
ansible-playbook -i inventory playbook.yml

# Limit hosts
ansible-playbook playbook.yml --limit webservers

# Extra variables
ansible-playbook playbook.yml -e "version=1.0"

# Check mode (dry run)
ansible-playbook playbook.yml --check --diff

# Tags
ansible-playbook playbook.yml --tags deploy
```

## Playbook Verification

```bash
# Syntax check
ansible-playbook playbook.yml --syntax-check

# List tasks
ansible-playbook playbook.yml --list-tasks

# List hosts
ansible-playbook playbook.yml --list-hosts
```

See example playbooks in this directory.
