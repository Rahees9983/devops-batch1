# ===========================================
# Terraform State - Examples and Demonstration
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # ===========================================
  # LOCAL BACKEND (Default)
  # State is stored in terraform.tfstate file
  # ===========================================
  # By default, Terraform uses local backend
  # State file is created in the current directory
}

provider "aws" {
  region = "us-east-1"
}

# ===========================================
# Resources to demonstrate state
# ===========================================

variable "environment" {
  default = "demo"
}

resource "random_id" "unique" {
  byte_length = 4
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    UniqueID    = random_id.unique.hex
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg-${random_id.unique.hex}"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-sg"
  }
}

# ===========================================
# Outputs to view in state
# ===========================================

output "vpc_id" {
  description = "VPC ID (stored in state)"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID (stored in state)"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security Group ID (stored in state)"
  value       = aws_security_group.web.id
}

output "state_commands" {
  description = "Useful state commands to try"
  value       = <<-EOT

    # List all resources in state
    terraform state list

    # Show specific resource
    terraform state show aws_vpc.main

    # Pull state to view
    terraform state pull | jq '.'

    # Show all outputs
    terraform output

    # Refresh state (detect drift)
    terraform plan -refresh-only

  EOT
}
