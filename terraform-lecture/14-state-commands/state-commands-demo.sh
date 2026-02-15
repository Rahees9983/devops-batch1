#!/bin/bash
# ===========================================
# Terraform State Commands Demo Script
# ===========================================

echo "============================================"
echo "TERRAFORM STATE COMMANDS DEMO"
echo "============================================"

# ===========================================
# terraform state list
# ===========================================
echo ""
echo "1. LIST ALL RESOURCES IN STATE"
echo "-------------------------------"
echo "Command: terraform state list"
echo ""
echo "# List all resources"
echo "terraform state list"
echo ""
echo "# Filter by resource type"
echo "terraform state list | grep aws_instance"
echo ""
echo "# List module resources"
echo "terraform state list module.vpc"

# ===========================================
# terraform state show
# ===========================================
echo ""
echo "2. SHOW RESOURCE DETAILS"
echo "-------------------------"
echo "Command: terraform state show <resource_address>"
echo ""
echo "# Show specific resource"
echo "terraform state show aws_instance.web"
echo ""
echo "# Show resource with count"
echo "terraform state show 'aws_instance.web[0]'"
echo ""
echo "# Show resource with for_each"
echo "terraform state show 'aws_instance.servers[\"web\"]'"
echo ""
echo "# Show module resource"
echo "terraform state show module.vpc.aws_vpc.main"

# ===========================================
# terraform state mv
# ===========================================
echo ""
echo "3. MOVE/RENAME RESOURCES"
echo "-------------------------"
echo "Command: terraform state mv <source> <destination>"
echo ""
echo "# Rename a resource"
echo "terraform state mv aws_instance.web aws_instance.web_server"
echo ""
echo "# Move into a module"
echo "terraform state mv aws_instance.web module.app.aws_instance.web"
echo ""
echo "# Move out of a module"
echo "terraform state mv module.app.aws_instance.web aws_instance.web"
echo ""
echo "# Rename a module"
echo "terraform state mv module.vpc module.network"
echo ""
echo "# Move between count indexes"
echo "terraform state mv 'aws_instance.web[0]' 'aws_instance.web[1]'"
echo ""
echo "# Convert from count to for_each"
echo "terraform state mv 'aws_instance.web[0]' 'aws_instance.web[\"server-1\"]'"
echo ""
echo "# Dry run (preview only)"
echo "terraform state mv -dry-run aws_instance.web aws_instance.web_server"

# ===========================================
# terraform state rm
# ===========================================
echo ""
echo "4. REMOVE FROM STATE"
echo "--------------------"
echo "Command: terraform state rm <resource_address>"
echo ""
echo "# Remove single resource (doesn't destroy actual resource)"
echo "terraform state rm aws_instance.web"
echo ""
echo "# Remove multiple resources"
echo "terraform state rm aws_instance.web aws_security_group.web"
echo ""
echo "# Remove indexed resource"
echo "terraform state rm 'aws_instance.web[0]'"
echo ""
echo "# Remove entire module"
echo "terraform state rm module.vpc"

# ===========================================
# terraform state pull
# ===========================================
echo ""
echo "5. PULL STATE"
echo "-------------"
echo "Command: terraform state pull"
echo ""
echo "# Output state to stdout"
echo "terraform state pull"
echo ""
echo "# Save state to backup file"
echo "terraform state pull > backup.tfstate"
echo ""
echo "# Parse with jq"
echo "terraform state pull | jq '.resources[].type'"
echo ""
echo "# Get specific resource"
echo "terraform state pull | jq '.resources[] | select(.type == \"aws_instance\")'"

# ===========================================
# terraform state push
# ===========================================
echo ""
echo "6. PUSH STATE (USE WITH CAUTION!)"
echo "----------------------------------"
echo "Command: terraform state push <file>"
echo ""
echo "# Push state from file"
echo "terraform state push backup.tfstate"
echo ""
echo "# Force push (override serial check)"
echo "terraform state push -force backup.tfstate"

# ===========================================
# terraform state replace-provider
# ===========================================
echo ""
echo "7. REPLACE PROVIDER"
echo "--------------------"
echo "Command: terraform state replace-provider <from> <to>"
echo ""
echo "# Replace provider"
echo "terraform state replace-provider hashicorp/aws registry.example.com/aws"
echo ""
echo "# Auto-approve"
echo "terraform state replace-provider -auto-approve hashicorp/aws registry.example.com/aws"

# ===========================================
# PRACTICAL EXAMPLES
# ===========================================
echo ""
echo "============================================"
echo "PRACTICAL EXAMPLES"
echo "============================================"

echo ""
echo "EXAMPLE 1: Refactoring Resource Names"
echo "--------------------------------------"
cat << 'EOF'
# Before: main.tf
resource "aws_instance" "my_instance" { ... }

# Step 1: Move in state
terraform state mv aws_instance.my_instance aws_instance.web_server

# Step 2: Update config to match
resource "aws_instance" "web_server" { ... }

# Step 3: Verify no changes
terraform plan  # Should show no changes
EOF

echo ""
echo "EXAMPLE 2: Moving Resource to Module"
echo "-------------------------------------"
cat << 'EOF'
# Step 1: Create the module structure
# modules/vpc/main.tf

# Step 2: Move resources to module
terraform state mv aws_vpc.main module.vpc.aws_vpc.main
terraform state mv aws_subnet.public module.vpc.aws_subnet.public

# Step 3: Update root module to use the module
module "vpc" {
  source = "./modules/vpc"
}

# Step 4: Verify
terraform plan
EOF

echo ""
echo "EXAMPLE 3: Converting count to for_each"
echo "----------------------------------------"
cat << 'EOF'
# Before:
resource "aws_instance" "server" {
  count = 3
  ...
}
# server[0], server[1], server[2]

# Move each instance
terraform state mv 'aws_instance.server[0]' 'aws_instance.server["web"]'
terraform state mv 'aws_instance.server[1]' 'aws_instance.server["app"]'
terraform state mv 'aws_instance.server[2]' 'aws_instance.server["db"]'

# After:
resource "aws_instance" "server" {
  for_each = toset(["web", "app", "db"])
  ...
}
EOF

echo ""
echo "EXAMPLE 4: Backup Before Changes"
echo "---------------------------------"
cat << 'EOF'
# Always backup before state operations
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# Make your changes
terraform state mv ...

# If something goes wrong, restore
terraform state push backup-20240115-103000.tfstate
EOF

echo ""
echo "EXAMPLE 5: Remove Resource from Management"
echo "-------------------------------------------"
cat << 'EOF'
# Resource exists but you want Terraform to stop managing it
terraform state rm aws_db_instance.legacy_database

# Remove from configuration
# Delete the resource block from .tf files

# The actual database still exists in AWS
# but Terraform no longer manages it
EOF
