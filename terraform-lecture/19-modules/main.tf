# ===========================================
# Modules - Root Module Example
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

variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default = "demo"
}

variable "project" {
  default = "myapp"
}

# ===========================================
# Get Available AZs
# ===========================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ===========================================
# Use Local Module
# ===========================================

module "vpc" {
  source = "./modules/vpc"

  name               = "${var.project}-${var.environment}"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  enable_nat_gateway = var.environment == "prod"
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ===========================================
# Use Registry Module
# ===========================================

# module "vpc_registry" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"
#
#   name = "${var.project}-${var.environment}"
#   cidr = "10.1.0.0/16"
#
#   azs             = slice(data.aws_availability_zones.available.names, 0, 2)
#   private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
#   public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]
#
#   enable_nat_gateway = true
#   single_nat_gateway = true
#
#   tags = {
#     Environment = var.environment
#     Project     = var.project
#   }
# }

# ===========================================
# Use Module with for_each
# ===========================================

variable "environments" {
  description = "Map of environments to create"
  default = {
    dev = {
      vpc_cidr       = "10.0.0.0/16"
      enable_nat     = false
    }
    staging = {
      vpc_cidr       = "10.1.0.0/16"
      enable_nat     = true
    }
  }
}

module "vpc_multi" {
  source   = "./modules/vpc"
  for_each = var.environments

  name               = "${var.project}-${each.key}"
  vpc_cidr           = each.value.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = [cidrsubnet(each.value.vpc_cidr, 8, 1), cidrsubnet(each.value.vpc_cidr, 8, 2)]
  private_subnet_cidrs = [cidrsubnet(each.value.vpc_cidr, 8, 10), cidrsubnet(each.value.vpc_cidr, 8, 20)]

  enable_nat_gateway = each.value.enable_nat
  single_nat_gateway = true

  tags = {
    Environment = each.key
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ===========================================
# Use Module with count (conditional)
# ===========================================

variable "create_extra_vpc" {
  default = false
}

module "vpc_optional" {
  source = "./modules/vpc"
  count  = var.create_extra_vpc ? 1 : 0

  name               = "${var.project}-extra"
  vpc_cidr           = "10.99.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = ["10.99.1.0/24", "10.99.2.0/24"]
  private_subnet_cidrs = ["10.99.10.0/24", "10.99.20.0/24"]

  enable_nat_gateway = false

  tags = {
    Environment = "extra"
    Project     = var.project
  }
}

# ===========================================
# Resources using Module Outputs
# ===========================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = module.vpc.private_subnet_ids[0]  # Using module output

  tags = {
    Name        = "${var.project}-${var.environment}-app"
    Environment = var.environment
  }
}

# ===========================================
# Outputs
# ===========================================

output "vpc_id" {
  description = "VPC ID from local module"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR from local module"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "multi_vpc_ids" {
  description = "VPC IDs from for_each module"
  value = {
    for env, vpc in module.vpc_multi :
    env => vpc.vpc_id
  }
}

output "app_instance_id" {
  description = "App instance ID"
  value       = aws_instance.app.id
}
