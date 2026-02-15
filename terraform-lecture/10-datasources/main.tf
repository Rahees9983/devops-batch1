# ===========================================
# Data Sources - Complete Examples
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
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

# ===========================================
# aws_ami - Find AMI Images
# ===========================================

# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ===========================================
# aws_availability_zones - Get AZs
# ===========================================

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# ===========================================
# aws_region - Current Region
# ===========================================

data "aws_region" "current" {}

# ===========================================
# aws_caller_identity - Current AWS Account
# ===========================================

data "aws_caller_identity" "current" {}

# ===========================================
# aws_vpc - Query Existing VPC
# ===========================================

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get VPC by tag (if exists)
# data "aws_vpc" "by_tag" {
#   filter {
#     name   = "tag:Name"
#     values = ["production-vpc"]
#   }
# }

# ===========================================
# aws_subnets - Query Multiple Subnets
# ===========================================

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ===========================================
# aws_iam_policy_document - Build IAM Policies
# ===========================================

# Assume role policy for EC2
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# S3 access policy
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "AllowS3List"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::my-bucket",
    ]
  }

  statement {
    sid    = "AllowS3ReadWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::my-bucket/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["private"]
    }
  }
}

# ===========================================
# http - Fetch Data from URL
# ===========================================

data "http" "my_public_ip" {
  url = "https://api.ipify.org?format=json"

  request_headers = {
    Accept = "application/json"
  }
}

# ===========================================
# Using Data Sources in Resources
# ===========================================

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Region      = data.aws_region.current.name
    Account     = data.aws_caller_identity.current.account_id
  }
}

# Create subnets using availability zones data source
resource "aws_subnet" "public" {
  count             = min(length(data.aws_availability_zones.available.names), 3)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Create EC2 instance using AMI data source
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name      = "${var.environment}-web"
    AMI       = data.aws_ami.amazon_linux_2.name
    AMIOwner  = data.aws_ami.amazon_linux_2.owner_id
    AccountID = data.aws_caller_identity.current.account_id
  }
}

# IAM Role using policy document data source
resource "aws_iam_role" "ec2_role" {
  name               = "${var.environment}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.environment}-ec2-role"
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "${var.environment}-s3-access"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# Security group with public IP
locals {
  my_ip = jsondecode(data.http.my_public_ip.response_body).ip
}

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]  # Only allow SSH from current IP
    description = "SSH from current IP"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
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
# Outputs - Data Source Information
# ===========================================

output "amazon_linux_2_ami" {
  description = "Amazon Linux 2 AMI details"
  value = {
    id           = data.aws_ami.amazon_linux_2.id
    name         = data.aws_ami.amazon_linux_2.name
    architecture = data.aws_ami.amazon_linux_2.architecture
  }
}

output "amazon_linux_2023_ami" {
  description = "Amazon Linux 2023 AMI ID"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "ubuntu_ami" {
  description = "Ubuntu AMI ID"
  value       = data.aws_ami.ubuntu.id
}

output "availability_zones" {
  description = "Available AZs in current region"
  value       = data.aws_availability_zones.available.names
}

output "current_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}

output "account_info" {
  description = "Current AWS account information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    arn        = data.aws_caller_identity.current.arn
    user_id    = data.aws_caller_identity.current.user_id
  }
}

output "default_vpc" {
  description = "Default VPC information"
  value = {
    id         = data.aws_vpc.default.id
    cidr_block = data.aws_vpc.default.cidr_block
  }
}

output "default_subnets" {
  description = "Default VPC subnet IDs"
  value       = data.aws_subnets.default.ids
}

output "my_public_ip" {
  description = "Your current public IP"
  value       = local.my_ip
}

output "ec2_assume_role_policy" {
  description = "EC2 assume role policy JSON"
  value       = data.aws_iam_policy_document.ec2_assume_role.json
}
