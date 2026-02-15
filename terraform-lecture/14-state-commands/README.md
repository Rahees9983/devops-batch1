# Terraform State Commands

## Overview

State commands allow you to inspect and modify Terraform state. Use them carefully as incorrect modifications can cause issues.

## Command Summary

| Command | Description |
|---------|-------------|
| `terraform state list` | List resources in state |
| `terraform state show` | Show a specific resource |
| `terraform state mv` | Move/rename resource |
| `terraform state rm` | Remove resource from state |
| `terraform state pull` | Download state to stdout |
| `terraform state push` | Upload state from stdin |
| `terraform state replace-provider` | Replace provider in state |

---

## terraform state list

Lists all resources tracked in state.

```bash
# List all resources
terraform state list

# Output:
# aws_instance.web
# aws_security_group.web
# aws_subnet.public
# aws_vpc.main

# List with filter
terraform state list aws_instance

# Output:
# aws_instance.web
# aws_instance.app

# List module resources
terraform state list module.vpc

# Output:
# module.vpc.aws_vpc.main
# module.vpc.aws_subnet.public[0]
# module.vpc.aws_subnet.public[1]
```

---

## terraform state show

Shows detailed information about a specific resource.

```bash
# Show specific resource
terraform state show aws_instance.web

# Output:
# resource "aws_instance" "web" {
#     ami                    = "ami-0c55b159cbfafe1f0"
#     arn                    = "arn:aws:ec2:us-east-1:123456789:instance/i-0abc123def456"
#     availability_zone      = "us-east-1a"
#     id                     = "i-0abc123def456"
#     instance_state         = "running"
#     instance_type          = "t2.micro"
#     private_ip             = "10.0.1.50"
#     public_ip              = "54.123.45.67"
#     subnet_id              = "subnet-abc123"
#     ...
# }

# Show resource in module
terraform state show module.vpc.aws_vpc.main

# Show resource with count
terraform state show 'aws_instance.web[0]'

# Show resource with for_each
terraform state show 'aws_instance.server["web"]'
```

---

## terraform state mv

Moves or renames resources in state without recreating them.

### Rename Resource

```bash
# Rename resource
terraform state mv aws_instance.web aws_instance.web_server

# Before:
# resource "aws_instance" "web" { ... }

# After (update your .tf file to match):
# resource "aws_instance" "web_server" { ... }
```

### Move Resource to Module

```bash
# Move resource into a module
terraform state mv aws_instance.web module.webserver.aws_instance.web

# Move resource out of a module
terraform state mv module.webserver.aws_instance.web aws_instance.web
```

### Move Entire Module

```bash
# Rename module
terraform state mv module.vpc module.network
```

### Move Indexed Resources

```bash
# Move count-indexed resource
terraform state mv 'aws_instance.web[0]' 'aws_instance.web[1]'

# Move from count to for_each
terraform state mv 'aws_instance.web[0]' 'aws_instance.web["server-1"]'
```

### Move to Different State File

```bash
# Move resource to another state file
terraform state mv -state-out=other.tfstate aws_instance.web aws_instance.web
```

### Dry Run

```bash
# Preview the move without making changes
terraform state mv -dry-run aws_instance.web aws_instance.web_server
```

---

## terraform state rm

Removes resources from state without destroying them. Useful when:
- Transferring resources to another state
- Removing resources from Terraform management
- Cleaning up abandoned resources

```bash
# Remove single resource
terraform state rm aws_instance.web

# Output:
# Removed aws_instance.web
# Successfully removed 1 resource instance(s).

# Remove multiple resources
terraform state rm aws_instance.web aws_security_group.web

# Remove all instances of a resource with count
terraform state rm 'aws_instance.web[0]'
terraform state rm 'aws_instance.web[1]'

# Remove resource with for_each
terraform state rm 'aws_instance.server["web"]'

# Remove entire module
terraform state rm module.vpc
```

### Warning

After `state rm`:
1. The resource still exists in your cloud provider
2. Running `terraform plan` will show it needs to be created
3. Update your configuration to avoid recreating

---

## terraform state pull

Downloads the state file to stdout. Useful for inspection or backup.

```bash
# Pull state and display
terraform state pull

# Save to file
terraform state pull > terraform.tfstate.backup

# Pretty print with jq
terraform state pull | jq '.'

# Extract specific information
terraform state pull | jq '.resources[].type'
terraform state pull | jq '.outputs'
```

---

## terraform state push

Uploads a state file from stdin. **Use with extreme caution!**

```bash
# Push state from file
terraform state push terraform.tfstate.backup

# Push with force (override serial check)
terraform state push -force terraform.tfstate.backup
```

### When to Use

- Recovering from backup
- Migrating between backends
- Fixing corrupted state (last resort)

### Warnings

1. Can overwrite team members' changes
2. May cause state inconsistencies
3. Use only when necessary

---

## terraform state replace-provider

Replaces provider references in state. Useful when:
- Provider is renamed
- Moving between provider registries
- Migrating to custom providers

```bash
# Replace provider
terraform state replace-provider hashicorp/aws registry.example.com/myorg/aws

# Replace provider with automatic approval
terraform state replace-provider -auto-approve hashicorp/aws registry.example.com/myorg/aws
```

---

## Practical Examples

### Example 1: Refactoring Resource Names

```hcl
# Before
resource "aws_instance" "my_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# Want to rename to "web_server"
```

```bash
# Step 1: Move in state
terraform state mv aws_instance.my_instance aws_instance.web_server

# Step 2: Update configuration
# Change "my_instance" to "web_server" in .tf file

# Step 3: Verify no changes
terraform plan
# Should show: No changes. Infrastructure is up-to-date.
```

### Example 2: Extracting Resources to Module

```hcl
# Before: main.tf
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

# After: modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr
}
```

```bash
# Move resources to module
terraform state mv aws_vpc.main module.vpc.aws_vpc.main
terraform state mv aws_subnet.public module.vpc.aws_subnet.public

# Update root configuration
# module "vpc" {
#   source      = "./modules/vpc"
#   vpc_cidr    = "10.0.0.0/16"
#   subnet_cidr = "10.0.1.0/24"
# }

# Verify
terraform plan
```

### Example 3: Converting count to for_each

```hcl
# Before: using count
resource "aws_instance" "server" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "server-${count.index}"
  }
}

# After: using for_each
resource "aws_instance" "server" {
  for_each      = toset(["server-0", "server-1", "server-2"])
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = each.key
  }
}
```

```bash
# Move each indexed resource to named
terraform state mv 'aws_instance.server[0]' 'aws_instance.server["server-0"]'
terraform state mv 'aws_instance.server[1]' 'aws_instance.server["server-1"]'
terraform state mv 'aws_instance.server[2]' 'aws_instance.server["server-2"]'

# Verify
terraform plan
```

### Example 4: Removing Resource from Management

```bash
# Resource exists but you want Terraform to stop managing it
terraform state rm aws_db_instance.legacy_database

# Remove from configuration
# Delete the resource block from .tf files

# Instance still exists in AWS but Terraform won't touch it
```

### Example 5: Backup and Restore State

```bash
# Backup current state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# If something goes wrong, restore
terraform state push backup-20240115-103000.tfstate
```

### Example 6: Inspect State for Debugging

```bash
# List all resources
terraform state list

# Find a specific resource type
terraform state list | grep aws_instance

# Show resource details
terraform state show aws_instance.web

# Get all resource IDs
terraform state pull | jq -r '.resources[].instances[].attributes.id'

# Get outputs
terraform state pull | jq '.outputs'
```

---

## State Command Flags

### Common Flags

```bash
# Specify state file location
terraform state list -state=other.tfstate

# Specify lock timeout
terraform state mv -lock-timeout=30s aws_instance.a aws_instance.b

# Disable locking
terraform state list -lock=false

# Backup state before modification
terraform state mv -backup=backup.tfstate aws_instance.a aws_instance.b
```

---

## Best Practices

1. **Always backup** before state modifications
   ```bash
   terraform state pull > backup.tfstate
   ```

2. **Use dry-run** when available
   ```bash
   terraform state mv -dry-run ...
   ```

3. **Verify with plan** after state changes
   ```bash
   terraform plan
   ```

4. **Work in maintenance window** to avoid conflicts

5. **Document state changes** for team awareness

6. **Avoid state push** unless absolutely necessary

7. **Use state locking** during modifications

---

## Lab Exercise

1. Create resources and examine state with `state list` and `state show`
2. Rename a resource using `state mv`
3. Move a resource into a module using `state mv`
4. Backup state using `state pull`
5. Remove a resource from state using `state rm` and verify it still exists
6. Convert count-based resources to for_each using `state mv`
