# ===========================================
# Conditional Expressions - Complete Examples
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
# Variables
# ===========================================

variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  default = "myapp"
}

variable "create_bastion" {
  description = "Whether to create bastion host"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Enable HTTPS ingress"
  type        = bool
  default     = true
}

# ===========================================
# Data Sources
# ===========================================

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
# BASIC CONDITIONAL: Simple Ternary
# ===========================================

locals {
  # Basic ternary: condition ? true_value : false_value
  instance_type = var.environment == "prod" ? "t2.large" : "t2.micro"

  # Multiple conditions (nested ternary)
  instance_type_nested = (
    var.environment == "prod" ? "t2.large" :
    var.environment == "staging" ? "t2.medium" :
    "t2.micro"  # default for dev
  )

  # Boolean helpers
  is_prod    = var.environment == "prod"
  is_staging = var.environment == "staging"
  is_dev     = var.environment == "dev"
}

# ===========================================
# CONDITIONAL RESOURCE CREATION (count)
# ===========================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.environment}-public-${count.index + 1}"
  }
}

# Create bastion only if var.create_bastion is true
resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-${var.environment}-bastion"
    Role = "bastion"
  }
}

# Create NAT Gateway only in prod
resource "aws_eip" "nat" {
  count  = var.environment == "prod" ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-nat-eip"
  }
}

# Create multiple instances in prod, fewer in other environments
resource "aws_instance" "web" {
  count = var.environment == "prod" ? 3 : var.environment == "staging" ? 2 : 1

  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id

  tags = {
    Name        = "${var.project}-${var.environment}-web-${count.index + 1}"
    Environment = var.environment
  }
}

# ===========================================
# CONDITIONAL ATTRIBUTE VALUES
# ===========================================

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type

  # Conditional attribute
  monitoring = var.environment == "prod" ? true : false

  subnet_id = aws_subnet.public[0].id

  # Conditional root volume size
  root_block_device {
    volume_size = var.environment == "prod" ? 100 : 20
    volume_type = var.environment == "prod" ? "gp3" : "gp2"
    encrypted   = local.is_prod
  }

  tags = {
    Name        = "${var.project}-${var.environment}-app"
    Environment = var.environment
    Critical    = local.is_prod ? "true" : "false"
  }
}

# ===========================================
# CONDITIONAL SECURITY GROUP RULES
# ===========================================

resource "aws_security_group" "web" {
  name        = "${var.project}-${var.environment}-web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id

  # Always allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-web-sg"
  }
}

# Conditional HTTPS rule
resource "aws_security_group_rule" "https" {
  count = var.enable_https ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS"
  security_group_id = aws_security_group.web.id
}

# SSH only in non-prod
resource "aws_security_group_rule" "ssh" {
  count = var.environment != "prod" ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SSH (dev/staging only)"
  security_group_id = aws_security_group.web.id
}

# ===========================================
# CONDITIONAL DYNAMIC BLOCKS
# ===========================================

variable "enable_extra_ports" {
  default = false
}

variable "extra_ports" {
  default = [8080, 8443, 9090]
}

resource "aws_security_group" "app" {
  name        = "${var.project}-${var.environment}-app-sg"
  description = "App server security group"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.enable_extra_ports ? var.extra_ports : []
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Port ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-app-sg"
  }
}

# ===========================================
# CONDITIONAL TAGS
# ===========================================

locals {
  # Base tags for all resources
  base_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Production-specific tags
  prod_tags = {
    Critical    = "true"
    BackupDaily = "true"
    Monitoring  = "enhanced"
  }

  # Merge tags conditionally
  all_tags = var.environment == "prod" ? merge(local.base_tags, local.prod_tags) : local.base_tags
}

# ===========================================
# CONDITIONAL OUTPUTS
# ===========================================

output "bastion_ip" {
  description = "Bastion public IP (if created)"
  value       = var.create_bastion ? aws_instance.bastion[0].public_ip : null
}

output "nat_gateway_ip" {
  description = "NAT Gateway IP (if created)"
  value       = var.environment == "prod" ? aws_eip.nat[0].public_ip : "No NAT Gateway in ${var.environment}"
}

output "environment_type" {
  description = "Environment classification"
  value       = local.is_prod ? "Production Environment" : "Non-Production Environment"
}

output "instance_count" {
  description = "Number of web instances"
  value       = length(aws_instance.web)
}

output "instance_ips" {
  description = "Web instance private IPs"
  value       = aws_instance.web[*].private_ip
}

output "conditional_summary" {
  value = <<-EOT

    Environment: ${var.environment}
    Instance Type: ${local.instance_type}
    Is Production: ${local.is_prod}
    Bastion Created: ${var.create_bastion}
    NAT Gateway: ${var.environment == "prod"}
    HTTPS Enabled: ${var.enable_https}
    Web Instance Count: ${length(aws_instance.web)}

  EOT
}
