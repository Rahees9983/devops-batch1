# ===========================================
# Terraform Local Values - Main Configuration
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

# ===========================================
# Variables
# ===========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "servers" {
  description = "Server configurations"
  type = list(object({
    name          = string
    instance_type = string
    disk_size     = number
  }))
  default = [
    { name = "web", instance_type = "t3.micro", disk_size = 20 },
    { name = "api", instance_type = "t3.small", disk_size = 30 },
    { name = "worker", instance_type = "t3.medium", disk_size = 50 }
  ]
}

# ===========================================
# Local Values - Basic Examples
# ===========================================

locals {
  # Simple string local
  app_name = "terraform-demo"

  # Combining variables
  name_prefix = "${var.project_name}-${var.environment}"

  # Lowercase and sanitized name for resources
  resource_name = lower(replace(local.name_prefix, "_", "-"))

  # Timestamp for tracking
  created_date = formatdate("YYYY-MM-DD", timestamp())
}

# ===========================================
# Local Values - Common Tags
# ===========================================

locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
    CreatedAt   = local.created_date
  }

  # Additional tags for specific resource types
  compute_tags = merge(local.common_tags, {
    ResourceType = "compute"
  })

  network_tags = merge(local.common_tags, {
    ResourceType = "network"
  })

  storage_tags = merge(local.common_tags, {
    ResourceType = "storage"
  })
}

# ===========================================
# Local Values - Conditional Logic
# ===========================================

locals {
  # Environment detection
  is_production  = var.environment == "prod" || var.environment == "production"
  is_staging     = var.environment == "staging" || var.environment == "stg"
  is_development = var.environment == "dev" || var.environment == "development"

  # Environment-based instance types
  instance_type = local.is_production ? "t3.large" : (
    local.is_staging ? "t3.medium" : "t3.micro"
  )

  # Environment-based instance count
  instance_count = local.is_production ? 3 : (local.is_staging ? 2 : 1)

  # Feature flags based on environment
  enable_enhanced_monitoring = local.is_production
  enable_deletion_protection = local.is_production
  enable_multi_az            = local.is_production || local.is_staging
  enable_encryption          = true  # Always encrypt

  # Storage configuration based on environment
  storage_config = {
    volume_type = local.is_production ? "gp3" : "gp2"
    volume_size = local.is_production ? 100 : (local.is_staging ? 50 : 20)
    iops        = local.is_production ? 3000 : null
    throughput  = local.is_production ? 125 : null
    encrypted   = local.enable_encryption
  }
}

# ===========================================
# Local Values - Network Calculations
# ===========================================

locals {
  # Calculate subnet CIDRs from VPC CIDR
  # Using cidrsubnet(prefix, newbits, netnum)
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),   # 10.0.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2),   # 10.0.2.0/24
    cidrsubnet(var.vpc_cidr, 8, 3)    # 10.0.3.0/24
  ]

  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 10),  # 10.0.10.0/24
    cidrsubnet(var.vpc_cidr, 8, 11),  # 10.0.11.0/24
    cidrsubnet(var.vpc_cidr, 8, 12)   # 10.0.12.0/24
  ]

  database_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 20),  # 10.0.20.0/24
    cidrsubnet(var.vpc_cidr, 8, 21)   # 10.0.21.0/24
  ]

  # All subnet CIDRs combined
  all_subnet_cidrs = concat(
    local.public_subnet_cidrs,
    local.private_subnet_cidrs,
    local.database_subnet_cidrs
  )

  # Availability zones
  availability_zones = [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c"
  ]
}

# ===========================================
# Local Values - Data Transformation
# ===========================================

locals {
  # Transform list to map for for_each
  servers_map = {
    for server in var.servers :
    server.name => server
  }

  # Add computed fields to server config
  servers_with_metadata = {
    for name, server in local.servers_map :
    name => merge(server, {
      full_name       = "${local.name_prefix}-${name}"
      is_large        = server.disk_size > 30
      instance_family = split(".", server.instance_type)[0]
    })
  }

  # Filter servers by criteria
  large_servers = {
    for name, server in local.servers_with_metadata :
    name => server
    if server.is_large
  }

  # Extract just server names
  server_names = [for server in var.servers : server.name]
}

# ===========================================
# Local Values - Resource Naming
# ===========================================

locals {
  # Centralized resource naming
  resource_names = {
    vpc              = "${local.name_prefix}-vpc"
    internet_gateway = "${local.name_prefix}-igw"
    nat_gateway      = "${local.name_prefix}-nat"
    public_subnet    = "${local.name_prefix}-public"
    private_subnet   = "${local.name_prefix}-private"
    security_group   = "${local.name_prefix}-sg"
    alb              = "${local.name_prefix}-alb"
    target_group     = "${local.name_prefix}-tg"
    launch_template  = "${local.name_prefix}-lt"
    asg              = "${local.name_prefix}-asg"
    s3_bucket        = "${local.resource_name}-data"
    rds              = "${local.name_prefix}-db"
    elasticache      = "${local.name_prefix}-cache"
  }

  # S3 bucket names (must be globally unique and lowercase)
  bucket_names = {
    logs    = "${local.resource_name}-logs-${data.aws_caller_identity.current.account_id}"
    data    = "${local.resource_name}-data-${data.aws_caller_identity.current.account_id}"
    backups = "${local.resource_name}-backups-${data.aws_caller_identity.current.account_id}"
  }
}

# ===========================================
# Local Values - Security Group Rules
# ===========================================

locals {
  # Ingress rules configuration
  default_ingress_rules = [
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH from internal network"
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    }
  ]

  # Additional rules for production
  production_ingress_rules = local.is_production ? [
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere (redirect to HTTPS)"
    }
  ] : []

  # Combined rules
  all_ingress_rules = concat(
    local.default_ingress_rules,
    local.production_ingress_rules
  )
}

# ===========================================
# Data Sources
# ===========================================

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
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
# Provider Configuration
# ===========================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ===========================================
# Resources Using Locals
# ===========================================

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.network_tags, {
    Name = local.resource_names.vpc
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(local.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index % length(local.availability_zones)]
  map_public_ip_on_launch = true

  tags = merge(local.network_tags, {
    Name = "${local.resource_names.public_subnet}-${count.index + 1}"
    Tier = "public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(local.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index % length(local.availability_zones)]

  tags = merge(local.network_tags, {
    Name = "${local.resource_names.private_subnet}-${count.index + 1}"
    Tier = "private"
  })
}

# Security Group with Dynamic Ingress Rules
resource "aws_security_group" "web" {
  name        = local.resource_names.security_group
  description = "Security group for ${local.name_prefix} web servers"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.all_ingress_rules
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
    description = "Allow all outbound traffic"
  }

  tags = merge(local.network_tags, {
    Name = local.resource_names.security_group
  })
}

# EC2 Instances using transformed locals
resource "aws_instance" "servers" {
  for_each = local.servers_with_metadata

  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.private[0].id

  vpc_security_group_ids = [aws_security_group.web.id]

  monitoring = local.enable_enhanced_monitoring

  root_block_device {
    volume_size           = each.value.disk_size
    volume_type           = local.storage_config.volume_type
    encrypted             = local.storage_config.encrypted
    delete_on_termination = !local.is_production
  }

  tags = merge(local.compute_tags, {
    Name         = each.value.full_name
    ServerRole   = each.key
    InstanceSize = each.value.is_large ? "large" : "small"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# ===========================================
# Outputs
# ===========================================

output "name_prefix" {
  description = "Resource name prefix"
  value       = local.name_prefix
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "is_production" {
  description = "Whether this is a production environment"
  value       = local.is_production
}

output "computed_instance_type" {
  description = "Instance type computed based on environment"
  value       = local.instance_type
}

output "public_subnet_cidrs" {
  description = "Computed public subnet CIDRs"
  value       = local.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "Computed private subnet CIDRs"
  value       = local.private_subnet_cidrs
}

output "servers_with_metadata" {
  description = "Server configurations with computed metadata"
  value       = local.servers_with_metadata
}

output "resource_names" {
  description = "All computed resource names"
  value       = local.resource_names
}

output "storage_config" {
  description = "Storage configuration based on environment"
  value       = local.storage_config
}

output "bucket_names" {
  description = "Computed S3 bucket names"
  value       = local.bucket_names
}
