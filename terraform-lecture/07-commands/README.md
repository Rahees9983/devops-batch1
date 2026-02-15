# Terraform Commands

## Essential Commands Overview

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize working directory |
| `terraform plan` | Preview changes |
| `terraform apply` | Apply changes |
| `terraform destroy` | Destroy infrastructure |
| `terraform validate` | Validate configuration |
| `terraform fmt` | Format configuration files |
| `terraform show` | Show current state |
| `terraform output` | Show outputs |

## terraform init

Initializes a working directory containing Terraform configuration files.

### Basic Usage

```bash
terraform init
```

### What it Does

1. Downloads provider plugins
2. Downloads modules
3. Initializes backend
4. Creates `.terraform` directory and `.terraform.lock.hcl`

### Common Options

```bash
# Upgrade providers to latest versions
terraform init -upgrade

# Reconfigure backend
terraform init -reconfigure

# Migrate state to new backend
terraform init -migrate-state

# Don't download providers (use cached)
terraform init -get-plugins=false

# Specify plugin directory
terraform init -plugin-dir=/path/to/plugins
```

### Example Output

```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...
- Installed hashicorp/aws v5.31.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

## terraform validate

Validates the configuration files for syntax and internal consistency.

```bash
terraform validate
```

### Example

```bash
# Valid configuration
$ terraform validate
Success! The configuration is valid.

# Invalid configuration
$ terraform validate
Error: Missing required argument

  on main.tf line 5, in resource "aws_instance" "web":
   5: resource "aws_instance" "web" {

The argument "ami" is required, but no definition was found.
```

## terraform fmt

Formats configuration files to a canonical format.

```bash
# Format current directory
terraform fmt

# Format recursively
terraform fmt -recursive

# Check formatting without modifying (useful in CI)
terraform fmt -check

# Show differences
terraform fmt -diff
```

### Example

```bash
$ terraform fmt -diff
main.tf
--- old/main.tf
+++ new/main.tf
@@ -1,4 +1,4 @@
 resource "aws_instance" "web" {
-ami = "ami-0c55b159cbfafe1f0"
-instance_type="t2.micro"
+  ami           = "ami-0c55b159cbfafe1f0"
+  instance_type = "t2.micro"
 }
```

## terraform plan

Creates an execution plan showing what changes will be made.

### Basic Usage

```bash
terraform plan
```

### Common Options

```bash
# Save plan to file
terraform plan -out=tfplan

# Plan for destroy
terraform plan -destroy

# Target specific resource
terraform plan -target=aws_instance.web

# Set variable
terraform plan -var="instance_type=t2.small"

# Use variable file
terraform plan -var-file="prod.tfvars"

# Refresh only (detect drift)
terraform plan -refresh-only

# Detailed exit codes for CI
terraform plan -detailed-exitcode
# Exit codes: 0 = no changes, 1 = error, 2 = changes present
```

### Plan Output Symbols

```
# Resource will be created
+ resource "aws_instance" "web" {

# Resource will be destroyed
- resource "aws_instance" "old" {

# Resource will be updated in-place
~ resource "aws_instance" "web" {
    ~ instance_type = "t2.micro" -> "t2.small"

# Resource will be replaced (destroy then create)
-/+ resource "aws_instance" "web" {

# Resource will be replaced (create then destroy)
+/- resource "aws_instance" "web" {

# Resource will be read (data source)
<= data "aws_ami" "example" {
```

## terraform apply

Applies the changes to reach the desired state.

### Basic Usage

```bash
# Interactive apply
terraform apply

# Apply saved plan (no confirmation needed)
terraform apply tfplan

# Auto-approve (skip confirmation)
terraform apply -auto-approve

# Target specific resource
terraform apply -target=aws_instance.web

# Replace specific resource
terraform apply -replace=aws_instance.web

# Refresh only (update state to match reality)
terraform apply -refresh-only
```

### Example Output

```
aws_instance.web: Creating...
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Still creating... [20s elapsed]
aws_instance.web: Creation complete after 25s [id=i-0abc123def456]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0abc123def456"
instance_public_ip = "54.123.45.67"
```

## terraform destroy

Destroys all resources managed by the configuration.

### Basic Usage

```bash
# Interactive destroy
terraform destroy

# Auto-approve
terraform destroy -auto-approve

# Target specific resource
terraform destroy -target=aws_instance.web

# Preview destroy
terraform plan -destroy
```

### Example

```bash
$ terraform destroy

aws_instance.web: Destroying... [id=i-0abc123def456]
aws_instance.web: Still destroying... [10s elapsed]
aws_instance.web: Destruction complete after 15s
aws_subnet.public: Destroying... [id=subnet-abc123]
aws_subnet.public: Destruction complete after 1s
aws_vpc.main: Destroying... [id=vpc-xyz789]
aws_vpc.main: Destruction complete after 1s

Destroy complete! Resources: 3 destroyed.
```

## terraform show

Shows the current state or a saved plan.

```bash
# Show current state
terraform show

# Show as JSON
terraform show -json

# Show saved plan
terraform show tfplan

# Show saved plan as JSON
terraform show -json tfplan
```

## terraform output

Displays output values.

```bash
# Show all outputs
terraform output

# Show specific output
terraform output instance_ip

# Raw value (no quotes)
terraform output -raw instance_ip

# JSON format
terraform output -json
```

## terraform refresh (Deprecated)

Updates state to match real infrastructure. Use `terraform apply -refresh-only` instead.

```bash
# Old way (deprecated)
terraform refresh

# New way
terraform apply -refresh-only
```

## terraform state Commands

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Move resource to different address
terraform state mv aws_instance.web aws_instance.web_server

# Remove resource from state (doesn't destroy)
terraform state rm aws_instance.web

# Pull state to stdout
terraform state pull

# Push state from stdin
terraform state push

# Replace provider in state
terraform state replace-provider hashicorp/aws registry.example.com/aws
```

## terraform workspace Commands

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev

# Select workspace
terraform workspace select prod

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete dev
```

## terraform import

Imports existing infrastructure into state.

```bash
terraform import aws_instance.web i-0abc123def456
```

## terraform taint / untaint (Deprecated)

Mark resource for recreation. Use `-replace` flag instead.

```bash
# Old way (deprecated)
terraform taint aws_instance.web

# New way
terraform apply -replace=aws_instance.web
```

## terraform graph

Generates a visual graph of resources.

```bash
# Generate DOT format
terraform graph

# Generate PNG (requires graphviz)
terraform graph | dot -Tpng > graph.png

# Generate SVG
terraform graph | dot -Tsvg > graph.svg
```

## terraform console

Interactive console for expressions.

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
> exit
```

## terraform providers

Shows provider requirements.

```bash
# List providers
terraform providers

# Lock provider versions
terraform providers lock

# Mirror providers
terraform providers mirror /path/to/directory
```

## terraform version

Shows Terraform version.

```bash
terraform version
# Output:
# Terraform v1.5.0
# on darwin_arm64
# + provider registry.terraform.io/hashicorp/aws v5.31.0
```

## Useful Command Combinations

### CI/CD Pipeline

```bash
#!/bin/bash
set -e

# Initialize
terraform init -input=false

# Validate
terraform validate

# Format check
terraform fmt -check -recursive

# Plan with detailed exit code
terraform plan -detailed-exitcode -out=tfplan

# Apply if there are changes
if [ $? -eq 2 ]; then
  terraform apply -auto-approve tfplan
fi
```

### Quick Apply Workflow

```bash
# Format, validate, and apply
terraform fmt && terraform validate && terraform apply
```

### Target Multiple Resources

```bash
terraform apply \
  -target=aws_instance.web \
  -target=aws_security_group.web
```

## Command Cheat Sheet

```bash
# Initialize
terraform init
terraform init -upgrade

# Validate & Format
terraform validate
terraform fmt -recursive

# Plan
terraform plan
terraform plan -out=tfplan
terraform plan -destroy

# Apply
terraform apply
terraform apply tfplan
terraform apply -auto-approve
terraform apply -replace=RESOURCE

# Destroy
terraform destroy
terraform destroy -target=RESOURCE

# State
terraform state list
terraform state show RESOURCE
terraform state mv OLD NEW
terraform state rm RESOURCE

# Output
terraform output
terraform output -raw NAME

# Workspace
terraform workspace list
terraform workspace new NAME
terraform workspace select NAME

# Debug
terraform console
terraform graph | dot -Tpng > graph.png
```

## Lab Exercise

Practice the following workflow:
1. `terraform init` - Initialize the project
2. `terraform fmt` - Format your code
3. `terraform validate` - Validate configuration
4. `terraform plan -out=tfplan` - Create a plan
5. `terraform apply tfplan` - Apply the plan
6. `terraform output` - View outputs
7. `terraform state list` - List resources
8. `terraform destroy` - Clean up
