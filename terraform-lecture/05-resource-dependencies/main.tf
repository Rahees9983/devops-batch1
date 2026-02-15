# ===========================================
# Resource Dependencies - Complete Examples
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
  default = "dev"
}

# ===========================================
# IMPLICIT DEPENDENCIES
# These are created automatically when you
# reference attributes from other resources
# ===========================================

# 1. VPC is created first (no dependencies)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# 2. Internet Gateway depends on VPC (implicit)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # <-- Creates implicit dependency

  tags = {
    Name = "${var.environment}-igw"
  }
}

# 3. Subnet depends on VPC (implicit)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id  # <-- Implicit dependency on VPC
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.environment}-private-subnet"
  }
}

# 4. Route Table depends on VPC and IGW (implicit)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # <-- Implicit dependency on IGW
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# 5. Route Table Association depends on Subnet and Route Table (implicit)
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id       # <-- Implicit dependency on Subnet
  route_table_id = aws_route_table.public.id  # <-- Implicit dependency on Route Table
}

# 6. Security Group depends on VPC (implicit)
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id  # <-- Implicit dependency on VPC

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# 7. EC2 Instance depends on Subnet and Security Group (implicit)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id              # <-- Implicit dependency
  vpc_security_group_ids = [aws_security_group.web.id]       # <-- Implicit dependency

  tags = {
    Name = "${var.environment}-web-server"
  }
}

# ===========================================
# EXPLICIT DEPENDENCIES (depends_on)
# Use when Terraform can't automatically detect
# the dependency relationship
# ===========================================

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.environment}-ec2-role"
  }
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.environment}-s3-access-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = ["${aws_s3_bucket.app_data.arn}", "${aws_s3_bucket.app_data.arn}/*"]
    }]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# S3 Bucket
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.environment}-app-data-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.environment}-app-data"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# EC2 Instance with EXPLICIT dependency on IAM policy
# The instance needs the policy to be attached, but doesn't reference it directly
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # EXPLICIT DEPENDENCY: Wait for the policy to be attached
  # Without this, the instance might start before the policy is ready
  depends_on = [aws_iam_role_policy.s3_access]

  user_data = <<-EOF
              #!/bin/bash
              aws s3 ls s3://${aws_s3_bucket.app_data.id}
              EOF

  tags = {
    Name = "${var.environment}-app-server"
  }
}

# ===========================================
# COMPLEX DEPENDENCY EXAMPLE
# Application that depends on database migration
# ===========================================

# Simulate database setup
resource "null_resource" "db_setup" {
  triggers = {
    db_instance = aws_instance.web.id
  }

  provisioner "local-exec" {
    command = "echo 'Database initialized for ${var.environment}'"
  }
}

# Simulate database migration
resource "null_resource" "db_migration" {
  triggers = {
    migration_version = "v1.0.0"
  }

  # Migration depends on db_setup
  depends_on = [null_resource.db_setup]

  provisioner "local-exec" {
    command = "echo 'Running database migrations...'"
  }
}

# Application startup depends on migrations being complete
resource "null_resource" "app_startup" {
  triggers = {
    instance_id = aws_instance.web.id
  }

  # EXPLICIT DEPENDENCY on migrations
  depends_on = [null_resource.db_migration]

  provisioner "local-exec" {
    command = "echo 'Starting application...'"
  }
}

# ===========================================
# AVOIDING CIRCULAR DEPENDENCIES
# ===========================================

# Security groups that reference each other
# This pattern avoids circular dependencies

resource "aws_security_group" "app_sg" {
  name        = "${var.environment}-app-sg"
  description = "Security group for app servers"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

# Separate rules avoid circular dependency
resource "aws_security_group_rule" "app_to_db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.app_sg.id
  description              = "MySQL from app servers"
}

resource "aws_security_group_rule" "db_to_app" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.db_sg.id
  description              = "Response traffic from DB"
}

# ===========================================
# OUTPUTS
# ===========================================

output "vpc_id" {
  value = aws_vpc.main.id
}

output "web_instance_id" {
  value = aws_instance.web.id
}

output "app_instance_id" {
  value = aws_instance.app.id
}

output "dependency_order" {
  description = "Order of resource creation"
  value = <<-EOT
    1. VPC
    2. Internet Gateway, Subnets (parallel - both depend on VPC)
    3. Route Table (depends on VPC and IGW)
    4. Security Groups (depend on VPC)
    5. IAM Role
    6. IAM Policy (depends on Role and S3 Bucket)
    7. EC2 Instances (depend on Subnet, SG, and optionally IAM)
    8. Route Table Associations
  EOT
}
