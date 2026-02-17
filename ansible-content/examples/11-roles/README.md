# Ansible Roles

## What are Roles?

Roles are a way to organize playbooks into reusable, modular components. They provide a standardized directory structure for grouping related tasks, handlers, variables, templates, and files.

## Role Directory Structure

```
roles/
└── webserver/
    ├── defaults/
    │   └── main.yml       # Default variables (lowest priority)
    ├── files/
    │   └── index.html     # Static files to copy
    ├── handlers/
    │   └── main.yml       # Handler definitions
    ├── meta/
    │   └── main.yml       # Role metadata and dependencies
    ├── tasks/
    │   └── main.yml       # Main task list
    ├── templates/
    │   └── nginx.conf.j2  # Jinja2 templates
    ├── vars/
    │   └── main.yml       # Role variables (high priority)
    └── README.md          # Documentation
```

## Creating a Role

```bash
# Initialize role structure
ansible-galaxy init roles/webserver

# Or create manually
mkdir -p roles/webserver/{tasks,handlers,templates,files,vars,defaults,meta}
```

## Using Roles

```yaml
# In playbook
- hosts: webservers
  roles:
    - webserver
    - role: database
      vars:
        db_name: myapp
```

## Role Search Path

1. `./roles/` in playbook directory
2. Configured `roles_path` in ansible.cfg
3. `~/.ansible/roles`
4. `/etc/ansible/roles`

## Galaxy Commands

```bash
ansible-galaxy install geerlingguy.nginx
ansible-galaxy list
ansible-galaxy remove geerlingguy.nginx
```

See the `webserver/` directory for a complete example role.
