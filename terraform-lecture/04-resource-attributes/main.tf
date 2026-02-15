# ===========================================
# Resource Attributes - Complete Examples
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

# ===========================================
# VPC Resource - Arguments and Attributes
# ===========================================

resource "aws_vpc" "main" {
  # ARGUMENTS (what you specify)
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# Using VPC ATTRIBUTES in other resources
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # <-- Using the 'id' attribute

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id          # <-- Using VPC id attribute
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)  # <-- Using cidr_block attribute
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 10)
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet"
  }
}

# ===========================================
# Route Table - Using Multiple Attributes
# ===========================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # <-- Using IGW id attribute
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id       # <-- Using subnet id attribute
  route_table_id = aws_route_table.public.id  # <-- Using route table id attribute
}

# ===========================================
# Security Group - Arguments and Attributes
# ===========================================

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id  # <-- Using VPC id attribute

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# ===========================================
# EC2 Instance - Using Multiple Resource Attributes
# ===========================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id  # <-- Using data source attribute
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id          # <-- Using subnet id attribute
  vpc_security_group_ids = [aws_security_group.web.id]   # <-- Using security group id attribute

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "web-server"
  }
}

# ===========================================
# EIP - Referencing Instance Attributes
# ===========================================

resource "aws_eip" "web" {
  instance = aws_instance.web.id  # <-- Using instance id attribute
  domain   = "vpc"

  tags = {
    Name = "web-eip"
  }
}

# ===========================================
# S3 Bucket - Various Attributes
# ===========================================

resource "aws_s3_bucket" "data" {
  bucket = "demo-attributes-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "data-bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id  # <-- Using bucket id attribute

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ===========================================
# Outputs - Demonstrating Available Attributes
# ===========================================

# VPC Attributes
output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_arn" {
  value = aws_vpc.main.arn
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "vpc_default_security_group" {
  value = aws_vpc.main.default_security_group_id
}

output "vpc_default_route_table" {
  value = aws_vpc.main.default_route_table_id
}

# Subnet Attributes
output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "public_subnet_arn" {
  value = aws_subnet.public.arn
}

output "public_subnet_az" {
  value = aws_subnet.public.availability_zone
}

# Security Group Attributes
output "security_group_id" {
  value = aws_security_group.web.id
}

output "security_group_arn" {
  value = aws_security_group.web.arn
}

output "security_group_vpc_id" {
  value = aws_security_group.web.vpc_id
}

# EC2 Instance Attributes
output "instance_id" {
  value = aws_instance.web.id
}

output "instance_arn" {
  value = aws_instance.web.arn
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "instance_private_ip" {
  value = aws_instance.web.private_ip
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
}

output "instance_private_dns" {
  value = aws_instance.web.private_dns
}

output "instance_az" {
  value = aws_instance.web.availability_zone
}

output "instance_state" {
  value = aws_instance.web.instance_state
}

# Nested Attributes
output "root_volume_id" {
  description = "Root volume ID (nested attribute)"
  value       = aws_instance.web.root_block_device[0].volume_id
}

output "root_volume_size" {
  description = "Root volume size"
  value       = aws_instance.web.root_block_device[0].volume_size
}

# S3 Bucket Attributes
output "bucket_id" {
  value = aws_s3_bucket.data.id
}

output "bucket_arn" {
  value = aws_s3_bucket.data.arn
}

output "bucket_domain_name" {
  value = aws_s3_bucket.data.bucket_domain_name
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.data.bucket_regional_domain_name
}

# EIP Attributes
output "eip_public_ip" {
  value = aws_eip.web.public_ip
}

output "eip_allocation_id" {
  value = aws_eip.web.allocation_id
}
