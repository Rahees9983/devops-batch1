# Variables and Jinja2

## Variable Types

1. **Simple Variables**: Strings, numbers, booleans
2. **Lists**: Ordered collections
3. **Dictionaries**: Key-value pairs
4. **Registered Variables**: Task output

## Variable Sources (Precedence - Lowest to Highest)

1. Role defaults (`defaults/main.yml`)
2. Inventory vars
3. Inventory group_vars
4. Inventory host_vars
5. Playbook group_vars
6. Playbook host_vars
7. Host facts
8. Play vars
9. Play vars_prompt
10. Play vars_files
11. Role vars (`vars/main.yml`)
12. Block vars
13. Task vars
14. include_vars
15. set_facts / registered vars
16. Extra vars (`-e`)

## Jinja2 Basics

- `{{ }}` - Variable output
- `{% %}` - Control statements (if/for/etc)
- `{# #}` - Comments

## Common Filters

| Filter | Example | Description |
|--------|---------|-------------|
| `default` | `{{ var \| default('N/A') }}` | Default value |
| `upper/lower` | `{{ name \| upper }}` | Case conversion |
| `join` | `{{ list \| join(',') }}` | Join list items |
| `length` | `{{ list \| length }}` | Count items |
| `first/last` | `{{ list \| first }}` | First/last item |
| `to_json/to_yaml` | `{{ dict \| to_json }}` | Format conversion |
| `regex_replace` | `{{ str \| regex_replace('old', 'new') }}` | Regex replace |

## Files in This Directory

- `variables.yml` - Variable examples
- `jinja2-filters.yml` - Filter examples
- `templates/` - Template examples
- `vars/` - Variable files

See example files for detailed demonstrations.
