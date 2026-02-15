# ===========================================
# Terraform Debugging Examples
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  default = "demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "enable_debug" {
  description = "Enable debug outputs"
  default     = true
}

# ===========================================
# Data Sources
# ===========================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  # Postcondition for validation
  lifecycle {
    postcondition {
      condition     = self.architecture == "x86_64"
      error_message = "Selected AMI must be x86_64 architecture."
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ===========================================
# Resources with Preconditions/Postconditions
# ===========================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  tags = {
    Name        = "${var.environment}-web"
    Environment = var.environment
  }

  # Precondition: Validate before creation
  lifecycle {
    precondition {
      condition     = contains(["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small"], var.instance_type)
      error_message = "Instance type must be t2.micro, t2.small, t2.medium, t3.micro, or t3.small."
    }

    postcondition {
      condition     = self.instance_state == "running" || self.instance_state == "pending"
      error_message = "Instance should be in running or pending state."
    }
  }
}

# ===========================================
# Debug Outputs
# ===========================================

# Basic debug info
output "debug_environment" {
  description = "Current environment"
  value       = var.enable_debug ? var.environment : null
}

output "debug_region" {
  description = "Current AWS region"
  value       = var.enable_debug ? data.aws_region.current.name : null
}

output "debug_account" {
  description = "Current AWS account"
  value       = var.enable_debug ? data.aws_caller_identity.current.account_id : null
}

output "debug_availability_zones" {
  description = "Available AZs"
  value       = var.enable_debug ? data.aws_availability_zones.available.names : null
}

# AMI debug info
output "debug_ami" {
  description = "Selected AMI details"
  value = var.enable_debug ? {
    id           = data.aws_ami.amazon_linux.id
    name         = data.aws_ami.amazon_linux.name
    architecture = data.aws_ami.amazon_linux.architecture
  } : null
}

# VPC debug info
output "debug_vpc" {
  description = "VPC details"
  value = var.enable_debug ? {
    id         = aws_vpc.main.id
    cidr_block = aws_vpc.main.cidr_block
    arn        = aws_vpc.main.arn
  } : null
}

# Instance debug info
output "debug_instance" {
  description = "Instance details"
  value = var.enable_debug ? {
    id            = aws_instance.web.id
    instance_type = aws_instance.web.instance_type
    private_ip    = aws_instance.web.private_ip
    public_ip     = aws_instance.web.public_ip
    state         = aws_instance.web.instance_state
    az            = aws_instance.web.availability_zone
    subnet_id     = aws_instance.web.subnet_id
  } : null
}

# ===========================================
# Debug Commands Reference
# ===========================================

output "debugging_commands" {
  description = "Useful debugging commands"
  value       = <<-EOT

    ===========================================
    TERRAFORM DEBUGGING COMMANDS
    ===========================================

    1. ENABLE LOGGING:
    ------------------
    # Set log level (TRACE, DEBUG, INFO, WARN, ERROR)
    export TF_LOG=DEBUG
    terraform plan

    # Log to file
    export TF_LOG_PATH="./terraform.log"
    export TF_LOG=DEBUG
    terraform plan

    # Provider-specific logging
    export TF_LOG_CORE=WARN
    export TF_LOG_PROVIDER=DEBUG
    terraform plan

    # Disable logging
    unset TF_LOG
    unset TF_LOG_PATH

    2. TERRAFORM CONSOLE:
    ---------------------
    # Interactive expression testing
    terraform console

    # Test expressions
    > var.environment
    > aws_instance.web.id
    > length(var.list)
    > cidrsubnet("10.0.0.0/16", 8, 1)

    3. VALIDATE:
    ------------
    terraform validate

    4. GRAPH:
    ---------
    # Generate dependency graph
    terraform graph
    terraform graph | dot -Tpng > graph.png

    5. PLAN OUTPUT:
    ---------------
    # Save plan for analysis
    terraform plan -out=tfplan
    terraform show tfplan
    terraform show -json tfplan > plan.json

    6. STATE INSPECTION:
    --------------------
    terraform state list
    terraform state show aws_instance.web
    terraform state pull | jq '.'

    7. REFRESH:
    -----------
    # Detect drift
    terraform plan -refresh-only

  EOT
}

# ===========================================
# Locals for debugging complex expressions
# ===========================================

locals {
  # Debug: Check variable values
  debug_vars = {
    environment   = var.environment
    instance_type = var.instance_type
    enable_debug  = var.enable_debug
  }

  # Debug: Complex calculation
  subnet_count = min(length(data.aws_availability_zones.available.names), 3)

  # Debug: Computed values
  resource_prefix = "${var.environment}-${data.aws_region.current.name}"
}

output "debug_locals" {
  description = "Debug local values"
  value       = var.enable_debug ? local.debug_vars : null
}
