#!/bin/bash
# ===========================================
# Terraform Commands Cheat Sheet
# ===========================================

echo "============================================"
echo "TERRAFORM COMMANDS REFERENCE"
echo "============================================"

# ===========================================
# INITIALIZATION
# ===========================================

# Initialize a working directory
terraform init

# Upgrade providers to latest allowed versions
terraform init -upgrade

# Reconfigure backend (for changing backends)
terraform init -reconfigure

# Migrate state to new backend
terraform init -migrate-state

# Initialize without downloading providers
terraform init -get-plugins=false

# ===========================================
# VALIDATION & FORMATTING
# ===========================================

# Validate configuration syntax
terraform validate

# Format configuration files
terraform fmt

# Format recursively
terraform fmt -recursive

# Check formatting (useful in CI/CD)
terraform fmt -check

# Show formatting differences
terraform fmt -diff

# ===========================================
# PLANNING
# ===========================================

# Create execution plan
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Plan for destruction
terraform plan -destroy

# Target specific resource
terraform plan -target=aws_instance.web

# Set variables via CLI
terraform plan -var="environment=prod"

# Use variable file
terraform plan -var-file="prod.tfvars"

# Refresh-only plan (detect drift)
terraform plan -refresh-only

# Detailed exit codes for CI/CD
terraform plan -detailed-exitcode
# Exit codes: 0 = no changes, 1 = error, 2 = changes present

# Plan without refresh (faster, but may miss drift)
terraform plan -refresh=false

# ===========================================
# APPLYING
# ===========================================

# Apply changes interactively
terraform apply

# Apply saved plan (no confirmation needed)
terraform apply tfplan

# Auto-approve (skip confirmation)
terraform apply -auto-approve

# Target specific resource
terraform apply -target=aws_instance.web

# Replace specific resource (recreate)
terraform apply -replace=aws_instance.web

# Refresh only (update state without changes)
terraform apply -refresh-only

# Parallelism (default is 10)
terraform apply -parallelism=5

# ===========================================
# DESTROYING
# ===========================================

# Destroy all resources
terraform destroy

# Destroy with auto-approve
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=aws_instance.web

# Preview destruction
terraform plan -destroy

# ===========================================
# STATE COMMANDS
# ===========================================

# List resources in state
terraform state list

# Show specific resource details
terraform state show aws_instance.web

# Move/rename resource in state
terraform state mv aws_instance.web aws_instance.web_server

# Remove resource from state (without destroying)
terraform state rm aws_instance.web

# Pull state to stdout (for backup)
terraform state pull > backup.tfstate

# Push state from file
terraform state push backup.tfstate

# Replace provider in state
terraform state replace-provider hashicorp/aws registry.example.com/aws

# ===========================================
# WORKSPACE COMMANDS
# ===========================================

# List workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Create new workspace
terraform workspace new dev

# Select workspace
terraform workspace select prod

# Delete workspace
terraform workspace delete dev

# ===========================================
# OUTPUT COMMANDS
# ===========================================

# Show all outputs
terraform output

# Show specific output
terraform output instance_ip

# Raw output (no quotes)
terraform output -raw instance_ip

# JSON format
terraform output -json

# ===========================================
# IMPORT
# ===========================================

# Import existing resource
terraform import aws_instance.web i-0abc123def456

# Import with module
terraform import module.vpc.aws_vpc.main vpc-abc123

# Import with count
terraform import 'aws_instance.web[0]' i-0abc123def456

# Import with for_each
terraform import 'aws_instance.web["server1"]' i-0abc123def456

# ===========================================
# VISUALIZATION
# ===========================================

# Generate dependency graph (DOT format)
terraform graph

# Generate PNG (requires graphviz)
terraform graph | dot -Tpng > graph.png

# Generate SVG
terraform graph | dot -Tsvg > graph.svg

# ===========================================
# DEBUGGING
# ===========================================

# Interactive console
terraform console

# Show current state
terraform show

# Show saved plan
terraform show tfplan

# Show as JSON
terraform show -json

# Version information
terraform version

# Provider information
terraform providers

# Lock providers
terraform providers lock

# ===========================================
# COMMON WORKFLOWS
# ===========================================

echo "============================================"
echo "COMMON WORKFLOWS"
echo "============================================"

# Standard workflow
echo "
1. terraform init
2. terraform validate
3. terraform fmt -check
4. terraform plan -out=tfplan
5. terraform apply tfplan
"

# Development workflow
echo "
terraform init
terraform validate && terraform fmt && terraform apply
"

# CI/CD workflow
echo "
terraform init -input=false
terraform validate
terraform fmt -check -recursive
terraform plan -detailed-exitcode -out=tfplan
if [ \$? -eq 2 ]; then
  terraform apply -auto-approve tfplan
fi
"

# State backup
echo "
terraform state pull > backup-\$(date +%Y%m%d-%H%M%S).tfstate
"

# Import workflow
echo "
1. Write resource configuration
2. terraform import <resource> <id>
3. terraform plan (should show no changes)
4. Adjust configuration if needed
"