# Terraform Debugging

## Overview

Debugging Terraform configurations involves using logging, validation tools, and systematic troubleshooting techniques to identify and resolve issues.

---

## TF_LOG Environment Variable

Control Terraform's logging verbosity using the `TF_LOG` environment variable.

### Log Levels

| Level | Description |
|-------|-------------|
| `TRACE` | Most verbose, shows all operations |
| `DEBUG` | Detailed debug information |
| `INFO` | General operational information |
| `WARN` | Warning messages |
| `ERROR` | Error messages only |

### Setting Log Level

```bash
# Linux/macOS
export TF_LOG=DEBUG
terraform plan

# Single command
TF_LOG=DEBUG terraform plan

# Windows (PowerShell)
$env:TF_LOG="DEBUG"
terraform plan

# Windows (CMD)
set TF_LOG=DEBUG
terraform plan
```

### Log to File

```bash
# Set log file path
export TF_LOG_PATH="./terraform.log"
export TF_LOG=DEBUG

terraform plan

# View the log
cat terraform.log
```

### Provider-Specific Logging

```bash
# Log only provider operations
export TF_LOG_CORE=WARN
export TF_LOG_PROVIDER=DEBUG

terraform plan
```

### Disable Logging

```bash
# Unset the variable
unset TF_LOG
unset TF_LOG_PATH

# Or set to empty
export TF_LOG=""
```

---

## Terraform Console

Interactive console for testing expressions and functions.

```bash
$ terraform console

> var.instance_type
"t2.micro"

> aws_instance.web.public_ip
"54.123.45.67"

> length(var.availability_zones)
3

> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"

> formatdate("YYYY-MM-DD", timestamp())
"2024-01-15"

> jsondecode(file("config.json"))
{
  "key" = "value"
}

> exit
```

### Testing Complex Expressions

```bash
$ terraform console

> [for s in ["a", "b", "c"] : upper(s)]
[
  "A",
  "B",
  "C",
]

> {for k, v in var.tags : k => lower(v)}
{
  "environment" = "production"
  "team" = "devops"
}

> var.enable_feature ? "enabled" : "disabled"
"enabled"
```

---

## terraform validate

Check configuration syntax and internal consistency.

```bash
$ terraform validate

# Success
Success! The configuration is valid.

# Error example
Error: Missing required argument

  on main.tf line 5, in resource "aws_instance" "web":
   5: resource "aws_instance" "web" {

The argument "ami" is required, but no definition was found.
```

### Validate Without State Access

```bash
# Skip backend initialization
terraform init -backend=false
terraform validate
```

---

## terraform plan for Debugging

Use plan output to understand what Terraform will do.

```bash
# Detailed plan output
terraform plan

# Save plan for analysis
terraform plan -out=debug.tfplan

# Show saved plan
terraform show debug.tfplan

# JSON output for parsing
terraform show -json debug.tfplan > plan.json
```

### Analyzing Plan Output

```bash
# Parse with jq
terraform show -json debug.tfplan | jq '.resource_changes[] | select(.change.actions | contains(["delete"]))'

# Find resources being replaced
terraform show -json debug.tfplan | jq '.resource_changes[] | select(.change.actions | contains(["delete", "create"]))'
```

---

## terraform graph

Visualize the dependency graph.

```bash
# Generate DOT format
terraform graph

# Generate PNG (requires graphviz)
terraform graph | dot -Tpng > graph.png

# Generate SVG
terraform graph | dot -Tsvg > graph.svg

# Open in browser (macOS)
terraform graph | dot -Tsvg > graph.svg && open graph.svg

# Plan graph
terraform graph -type=plan

# Apply graph
terraform graph -type=apply
```

---

## Common Debugging Scenarios

### Scenario 1: Provider Authentication Issues

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Look for authentication errors in output
# Example error:
# Error: error configuring Terraform AWS Provider: no valid credential sources

# Check credentials
aws sts get-caller-identity
```

### Scenario 2: Resource Creation Failure

```bash
# Get detailed error
export TF_LOG=DEBUG
terraform apply

# Check specific resource state
terraform state show aws_instance.web

# Check provider API response in logs
grep -i "error\|fail" terraform.log
```

### Scenario 3: State Issues

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Pull and inspect state
terraform state pull | jq '.'

# Check state version
terraform state pull | jq '.version, .terraform_version, .serial'
```

### Scenario 4: Dependency Problems

```bash
# Generate and view graph
terraform graph | dot -Tpng > deps.png

# Check implicit dependencies
terraform plan -target=aws_instance.web

# Look for circular dependencies
terraform validate
```

### Scenario 5: Variable/Expression Issues

```bash
# Test in console
terraform console

> var.my_variable
> local.my_local
> aws_instance.web.id

# Check variable precedence
terraform plan -var="debug_var=test"
```

---

## Debug Outputs

Add temporary outputs for debugging.

```hcl
# Temporary debug outputs
output "debug_vpc_id" {
  value = aws_vpc.main.id
}

output "debug_subnet_cidrs" {
  value = aws_subnet.private[*].cidr_block
}

output "debug_computed_value" {
  value = local.computed_config
}

# Debug locals
locals {
  debug_info = {
    vpc_id      = aws_vpc.main.id
    environment = var.environment
    timestamp   = timestamp()
  }
}

output "debug_all" {
  value = local.debug_info
}
```

---

## Using Preconditions and Postconditions

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    # Validate before creation
    precondition {
      condition     = can(regex("^ami-", var.ami_id))
      error_message = "AMI ID must start with 'ami-'. Got: ${var.ami_id}"
    }

    # Validate after creation
    postcondition {
      condition     = self.public_ip != null && self.public_ip != ""
      error_message = "Instance should have a public IP but got: ${self.public_ip}"
    }
  }
}

# Validate data source
data "aws_ami" "selected" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }

  lifecycle {
    postcondition {
      condition     = self.architecture == "x86_64"
      error_message = "Selected AMI must be x86_64 architecture"
    }
  }
}
```

---

## Crash Logs

When Terraform crashes, it creates a crash log.

```bash
# Crash log location
ls crash.log

# View crash log
cat crash.log

# Report a bug with crash log
# Include: crash.log, terraform version, OS info
```

### Generating Debug Bundle

```bash
# Create debug bundle
mkdir terraform-debug
cp crash.log terraform-debug/
terraform version > terraform-debug/version.txt
cp *.tf terraform-debug/
terraform state pull > terraform-debug/state.json 2>/dev/null
zip -r terraform-debug.zip terraform-debug/
```

---

## Check Mode (Dry Run)

```bash
# Plan without making changes
terraform plan

# Plan with refresh
terraform plan -refresh=true

# Plan without refresh (faster)
terraform plan -refresh=false

# Refresh-only plan (detect drift)
terraform plan -refresh-only
```

---

## Debugging Scripts

### Debug Helper Script

```bash
#!/bin/bash
# debug-terraform.sh

echo "=== Terraform Debug Info ==="
echo "Terraform Version:"
terraform version
echo ""

echo "Provider Versions:"
terraform providers
echo ""

echo "Workspace:"
terraform workspace show
echo ""

echo "State Resources:"
terraform state list 2>/dev/null || echo "No state file"
echo ""

echo "Variables (from tfvars):"
cat *.tfvars 2>/dev/null || echo "No tfvars files"
echo ""

echo "Validating Configuration:"
terraform validate
echo ""

echo "=== Running Plan with Debug Logging ==="
TF_LOG=DEBUG terraform plan 2>&1 | tee debug-plan.log

echo ""
echo "Debug log saved to: debug-plan.log"
```

### Parse Plan JSON

```bash
#!/bin/bash
# analyze-plan.sh

terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json

echo "Resources to be created:"
jq '.resource_changes[] | select(.change.actions | contains(["create"])) | .address' plan.json

echo "Resources to be destroyed:"
jq '.resource_changes[] | select(.change.actions | contains(["delete"])) | .address' plan.json

echo "Resources to be updated:"
jq '.resource_changes[] | select(.change.actions | contains(["update"])) | .address' plan.json

echo "Resources to be replaced:"
jq '.resource_changes[] | select(.change.actions | contains(["delete", "create"])) | .address' plan.json
```

---

## Common Errors and Solutions

### Error: Provider Configuration

```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Set credentials
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"
```

### Error: State Lock

```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Wait for other operation to complete, or:
terraform force-unlock LOCK_ID
```

### Error: Cycle Detected

```
Error: Cycle: aws_security_group.a, aws_security_group.b
```

**Solution:**
Use separate security group rules instead of inline rules.

### Error: Resource Not Found

```
Error: ResourceNotFoundException: Instance not found
```

**Solution:**
```bash
# Refresh state
terraform refresh

# Or remove from state
terraform state rm aws_instance.web
```

---

## Best Practices

1. **Start with validation** - Run `terraform validate` first
2. **Use incremental logging** - Start with INFO, escalate to DEBUG/TRACE
3. **Log to file** - Use TF_LOG_PATH for easier analysis
4. **Test expressions** - Use `terraform console` liberally
5. **Visualize dependencies** - Use `terraform graph` for complex configs
6. **Check state** - Use state commands to verify resource status
7. **Read error messages** - Terraform errors are usually descriptive

---

## Lab Exercise

1. Enable DEBUG logging and run terraform plan
2. Use terraform console to test expressions
3. Generate and view a dependency graph
4. Create debug outputs for troubleshooting
5. Parse plan JSON to find resources being changed
