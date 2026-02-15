# ===========================================
# Terraform Taints and Replace Examples
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  default = "demo"
}

variable "ami_version" {
  description = "Version of AMI to use"
  default     = "v1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ===========================================
# Resources for Taint/Replace Demo
# ===========================================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

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

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Web server security group"
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
# Instance to demonstrate replacement
# ===========================================

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name       = "${var.environment}-web"
    Version    = var.ami_version
    ManagedBy  = "terraform"
  }
}

# ===========================================
# Instance with create_before_destroy
# Zero-downtime replacement
# ===========================================

resource "aws_instance" "web_zero_downtime" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "${var.environment}-web-zero-downtime"
    Version = var.ami_version
  }
}

# ===========================================
# Instance with replace_triggered_by
# Auto-replace when dependency changes
# ===========================================

resource "aws_instance" "web_auto_replace" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  lifecycle {
    replace_triggered_by = [
      aws_security_group.web.id  # Replace when SG changes
    ]
  }

  tags = {
    Name    = "${var.environment}-web-auto-replace"
    Version = var.ami_version
  }
}

# ===========================================
# Multiple instances for rolling replacement
# ===========================================

resource "aws_instance" "web_cluster" {
  count = 3

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "${var.environment}-web-${count.index + 1}"
    Index   = count.index
    Version = var.ami_version
  }
}

# ===========================================
# Outputs
# ===========================================

output "instance_id" {
  value = aws_instance.web.id
}

output "cluster_instance_ids" {
  value = aws_instance.web_cluster[*].id
}

output "taint_replace_commands" {
  value = <<-EOT

    ===========================================
    TAINT/REPLACE COMMANDS (Modern Approach)
    ===========================================

    The 'terraform taint' command is DEPRECATED since v0.15.2
    Use 'terraform apply -replace' instead:

    # Replace a single resource
    terraform apply -replace="aws_instance.web"

    # Preview replacement first
    terraform plan -replace="aws_instance.web"

    # Replace multiple resources
    terraform apply \
      -replace="aws_instance.web" \
      -replace="aws_security_group.web"

    # Replace indexed resource
    terraform apply -replace="aws_instance.web_cluster[0]"

    # Replace for_each resource
    terraform apply -replace='aws_instance.servers["web"]'

    # Replace module resource
    terraform apply -replace="module.app.aws_instance.server"

    ===========================================
    ROLLING REPLACEMENT (Manual)
    ===========================================

    # Replace instances one at a time:
    terraform apply -replace="aws_instance.web_cluster[0]"
    # Wait for health check...
    terraform apply -replace="aws_instance.web_cluster[1]"
    # Wait for health check...
    terraform apply -replace="aws_instance.web_cluster[2]"

    ===========================================
    LEGACY COMMANDS (Deprecated)
    ===========================================

    # Old way (don't use):
    terraform taint aws_instance.web
    terraform apply

    # Untaint:
    terraform untaint aws_instance.web

  EOT
}
