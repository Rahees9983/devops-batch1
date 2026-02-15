# ===========================================
# Terraform Workspaces - Complete Examples
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ===========================================
  # S3 Backend with Workspace Support
  # ===========================================
  # Uncomment to use S3 backend with workspaces
  #
  # backend "s3" {
  #   bucket               = "my-terraform-state-bucket"
  #   key                  = "app/terraform.tfstate"
  #   region               = "us-east-1"
  #   workspace_key_prefix = "environments"
  #   dynamodb_table       = "terraform-locks"
  #   encrypt              = true
  # }
  #
  # This creates state files like:
  # s3://my-terraform-state-bucket/environments/dev/app/terraform.tfstate
  # s3://my-terraform-state-bucket/environments/prod/app/terraform.tfstate
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

variable "project" {
  default = "myapp"
}

# ===========================================
# Workspace-Based Configuration
# ===========================================

locals {
  # Current workspace name
  environment = terraform.workspace

  # Handle "default" workspace
  env = terraform.workspace == "default" ? "dev" : terraform.workspace

  # Configuration per workspace
  workspace_config = {
    default = {
      instance_type  = "t2.micro"
      instance_count = 1
      vpc_cidr       = "10.0.0.0/16"
      enable_nat     = false
      disk_size      = 20
    }
    dev = {
      instance_type  = "t2.micro"
      instance_count = 1
      vpc_cidr       = "10.0.0.0/16"
      enable_nat     = false
      disk_size      = 20
    }
    staging = {
      instance_type  = "t2.small"
      instance_count = 2
      vpc_cidr       = "10.1.0.0/16"
      enable_nat     = true
      disk_size      = 30
    }
    prod = {
      instance_type  = "t2.large"
      instance_count = 3
      vpc_cidr       = "10.2.0.0/16"
      enable_nat     = true
      disk_size      = 100
    }
  }

  # Get current workspace config (with default fallback)
  config = lookup(local.workspace_config, terraform.workspace, local.workspace_config["default"])

  # Common tags including workspace
  tags = {
    Project     = var.project
    Environment = local.env
    Workspace   = terraform.workspace
    ManagedBy   = "terraform"
  }
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
# Resources using workspace configuration
# ===========================================

resource "aws_vpc" "main" {
  cidr_block           = local.config.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.project}-${local.env}-vpc"
  })
}

resource "aws_subnet" "public" {
  count = min(local.config.instance_count, length(data.aws_availability_zones.available.names))

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.config.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project}-${local.env}-public-${count.index + 1}"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.project}-${local.env}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${var.project}-${local.env}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (only if enabled for workspace)
resource "aws_eip" "nat" {
  count  = local.config.enable_nat ? 1 : 0
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${var.project}-${local.env}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  count = local.config.enable_nat ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.tags, {
    Name = "${var.project}-${local.env}-nat"
  })
}

resource "aws_security_group" "web" {
  name        = "${var.project}-${local.env}-web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id

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

  # SSH only in dev/staging
  dynamic "ingress" {
    for_each = local.env != "prod" ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH (non-prod only)"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project}-${local.env}-web-sg"
  })
}

resource "aws_instance" "web" {
  count = local.config.instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = local.config.instance_type
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.web.id]

  root_block_device {
    volume_size = local.config.disk_size
    encrypted   = true
  }

  tags = merge(local.tags, {
    Name  = "${var.project}-${local.env}-web-${count.index + 1}"
    Index = count.index
  })
}

# ===========================================
# Outputs
# ===========================================

output "workspace" {
  description = "Current workspace name"
  value       = terraform.workspace
}

output "environment" {
  description = "Resolved environment name"
  value       = local.env
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "instance_count" {
  description = "Number of web instances"
  value       = length(aws_instance.web)
}

output "instance_type" {
  description = "Instance type used"
  value       = local.config.instance_type
}

output "instance_ips" {
  description = "Web instance public IPs"
  value       = aws_instance.web[*].public_ip
}

output "nat_gateway_enabled" {
  description = "Whether NAT Gateway is enabled"
  value       = local.config.enable_nat
}

output "workspace_commands" {
  value = <<-EOT

    ===========================================
    TERRAFORM WORKSPACE COMMANDS
    ===========================================

    # List all workspaces
    terraform workspace list

    # Show current workspace
    terraform workspace show

    # Create new workspace
    terraform workspace new dev
    terraform workspace new staging
    terraform workspace new prod

    # Select workspace
    terraform workspace select dev
    terraform workspace select prod

    # Delete workspace (must switch away first)
    terraform workspace select default
    terraform workspace delete dev

    ===========================================
    WORKFLOW EXAMPLE
    ===========================================

    # Create and deploy to dev
    terraform workspace new dev
    terraform plan
    terraform apply

    # Create and deploy to staging
    terraform workspace new staging
    terraform plan
    terraform apply

    # Create and deploy to prod
    terraform workspace new prod
    terraform plan
    terraform apply

    # Switch between environments
    terraform workspace select dev
    terraform plan  # Shows dev resources

    terraform workspace select prod
    terraform plan  # Shows prod resources

  EOT
}

output "configuration_summary" {
  value = <<-EOT

    ===========================================
    CURRENT WORKSPACE CONFIGURATION
    ===========================================

    Workspace:      ${terraform.workspace}
    Environment:    ${local.env}
    VPC CIDR:       ${local.config.vpc_cidr}
    Instance Type:  ${local.config.instance_type}
    Instance Count: ${local.config.instance_count}
    Disk Size:      ${local.config.disk_size} GB
    NAT Gateway:    ${local.config.enable_nat}

  EOT
}
