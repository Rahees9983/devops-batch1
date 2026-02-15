# ===========================================
# Output Variables - Complete Examples
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
}

provider "aws" {
  region = var.aws_region
}

# ===========================================
# Variables
# ===========================================
variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "instance_count" {
  default = 3
}

# ===========================================
# Resources
# ===========================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name        = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
    Index       = count.index
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# ===========================================
# BASIC OUTPUTS
# ===========================================

# Simple string output
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

# Output with ARN
output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Output CIDR block
output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# ===========================================
# LIST OUTPUTS (using splat expression)
# ===========================================

# List of subnet IDs
output "subnet_ids" {
  description = "List of subnet IDs"
  value       = aws_subnet.public[*].id
}

# List of subnet CIDRs
output "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

# List of availability zones used
output "availability_zones" {
  description = "Availability zones used"
  value       = aws_subnet.public[*].availability_zone
}

# List of instance IDs
output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.web[*].id
}

# List of public IPs
output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = aws_instance.web[*].public_ip
}

# List of private IPs
output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.web[*].private_ip
}

# ===========================================
# MAP OUTPUTS (using for expressions)
# ===========================================

# Map of instance name to ID
output "instance_name_to_id" {
  description = "Map of instance names to their IDs"
  value = {
    for instance in aws_instance.web :
    instance.tags.Name => instance.id
  }
}

# Map of instance name to IP
output "instance_name_to_ip" {
  description = "Map of instance names to their public IPs"
  value = {
    for instance in aws_instance.web :
    instance.tags.Name => instance.public_ip
  }
}

# Detailed instance information
output "instance_details" {
  description = "Detailed information about each instance"
  value = {
    for idx, instance in aws_instance.web :
    instance.tags.Name => {
      id            = instance.id
      public_ip     = instance.public_ip
      private_ip    = instance.private_ip
      instance_type = instance.instance_type
      az            = instance.availability_zone
      subnet_id     = instance.subnet_id
    }
  }
}

# ===========================================
# OBJECT OUTPUT
# ===========================================

output "vpc_info" {
  description = "Complete VPC information"
  value = {
    id         = aws_vpc.main.id
    arn        = aws_vpc.main.arn
    cidr_block = aws_vpc.main.cidr_block
    dns_support = aws_vpc.main.enable_dns_support
    dns_hostnames = aws_vpc.main.enable_dns_hostnames
  }
}

output "infrastructure_summary" {
  description = "Summary of all infrastructure"
  value = {
    environment     = var.environment
    region          = var.aws_region
    vpc_id          = aws_vpc.main.id
    subnet_count    = length(aws_subnet.public)
    instance_count  = length(aws_instance.web)
    security_groups = [aws_security_group.web.id]
  }
}

# ===========================================
# SENSITIVE OUTPUT
# ===========================================

output "db_password" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}

# ===========================================
# CONDITIONAL OUTPUT
# ===========================================

output "environment_type" {
  description = "Type of environment"
  value       = var.environment == "prod" ? "Production Environment" : "Non-Production Environment"
}

# ===========================================
# FORMATTED OUTPUT
# ===========================================

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for instance in aws_instance.web :
    "ssh -i key.pem ec2-user@${instance.public_ip}"
  ]
}

output "connection_info" {
  description = "Connection information formatted"
  value = join("\n", [
    for idx, instance in aws_instance.web :
    format("Instance %d: ssh ec2-user@%s", idx + 1, instance.public_ip)
  ])
}

# ===========================================
# DEPENDS_ON OUTPUT
# ===========================================

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.web[0].public_dns}"
  depends_on  = [aws_security_group.web]
}

# ===========================================
# JSON ENCODED OUTPUT
# ===========================================

output "instance_config_json" {
  description = "Instance configuration as JSON"
  value = jsonencode({
    instances = [
      for instance in aws_instance.web : {
        name = instance.tags.Name
        ip   = instance.public_ip
        az   = instance.availability_zone
      }
    ]
  })
}
