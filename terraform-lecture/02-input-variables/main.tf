# ===========================================
# Input Variables - Main Configuration
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
  region = var.aws_region
}

# ===========================================
# Using Variables in Resources
# ===========================================

# VPC using string variable
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  })
}

# Subnets using list variable
resource "aws_subnet" "public" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = var.enable_public_ip

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-subnet-${count.index + 1}"
    Environment = var.environment
  })
}

# Security Group using list of objects
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-web-sg"
    Environment = var.environment
  })
}

# EC2 Instances using map and object variables
resource "aws_instance" "servers" {
  for_each = var.servers

  ami           = lookup(var.ami_ids, var.aws_region, var.instance_config.ami_id)
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[each.value.subnet_index].id

  vpc_security_group_ids = [aws_security_group.web.id]

  monitoring = var.enable_monitoring

  root_block_device {
    volume_size = each.value.disk_size
    encrypted   = var.enable_encryption
  }

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}"
      Environment = var.environment
    }
  )
}

# Using instance_type from map based on environment
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = lookup(var.ami_ids, var.aws_region, "ami-0c55b159cbfafe1f0")
  instance_type = lookup(var.instance_types, var.environment, "t2.micro")
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id

  vpc_security_group_ids = [aws_security_group.web.id]

  root_block_device {
    volume_size = var.disk_size_gb
    encrypted   = var.enable_encryption
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-web-${count.index + 1}"
    Environment = var.environment
  })
}

# ===========================================
# Outputs showing variable usage
# ===========================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "instance_type_used" {
  description = "Instance type used for this environment"
  value       = lookup(var.instance_types, var.environment, "t2.micro")
}

output "server_details" {
  description = "Details of all servers"
  value = {
    for name, instance in aws_instance.servers :
    name => {
      id         = instance.id
      private_ip = instance.private_ip
      type       = instance.instance_type
    }
  }
}
