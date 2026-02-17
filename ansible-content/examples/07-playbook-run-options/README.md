# Playbook Run Options

## Basic Execution

```bash
# Run playbook
ansible-playbook playbook.yml

# Specify inventory
ansible-playbook -i inventory/hosts playbook.yml

# Limit to specific hosts
ansible-playbook playbook.yml --limit webservers
ansible-playbook playbook.yml -l "web1,web2"
```

## Check Mode (Dry Run)

```bash
# Dry run - no changes made
ansible-playbook playbook.yml --check

# Check mode with diff (show what would change)
ansible-playbook playbook.yml --check --diff

# Check mode with verbose output
ansible-playbook playbook.yml --check -v
```

## Start At Task

```bash
# List all tasks
ansible-playbook playbook.yml --list-tasks

# Start at specific task
ansible-playbook playbook.yml --start-at-task="Install nginx"

# Step through tasks interactively
ansible-playbook playbook.yml --step
```

## Tags

```bash
# Run only tagged tasks
ansible-playbook playbook.yml --tags "install,configure"

# Skip specific tags
ansible-playbook playbook.yml --skip-tags "cleanup"

# List all available tags
ansible-playbook playbook.yml --list-tags

# Run 'always' and specified tags
ansible-playbook playbook.yml --tags "deploy"
```

## Verbosity

```bash
ansible-playbook playbook.yml -v      # verbose
ansible-playbook playbook.yml -vv     # more verbose
ansible-playbook playbook.yml -vvv    # debug
ansible-playbook playbook.yml -vvvv   # connection debug
```

## Extra Variables

```bash
# Pass single variable
ansible-playbook playbook.yml -e "version=1.2.3"

# Pass multiple variables
ansible-playbook playbook.yml -e "version=1.2.3 env=prod"

# Pass JSON
ansible-playbook playbook.yml -e '{"version": "1.2.3", "env": "prod"}'

# Pass from file
ansible-playbook playbook.yml -e "@vars.yml"
```

See example files for detailed demonstrations.
