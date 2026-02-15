# ===========================================
# Meta-Arguments - count and for_each Examples
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

variable "environment" {
  default = "demo"
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

# ===========================================
# COUNT - Basic Usage
# ===========================================

# Create multiple instances with count
resource "aws_instance" "count_basic" {
  count = 3

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name  = "${var.environment}-server-${count.index + 1}"
    Index = count.index
  }
}

# ===========================================
# COUNT - Conditional Creation
# ===========================================

variable "create_bastion" {
  description = "Whether to create bastion host"
  default     = true
}

resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "${var.environment}-bastion"
    Role = "bastion"
  }
}

# ===========================================
# COUNT - With Lists
# ===========================================

variable "instance_names" {
  description = "Names for instances"
  default     = ["web", "app", "cache"]
}

resource "aws_instance" "named" {
  count = length(var.instance_names)

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "${var.environment}-${var.instance_names[count.index]}"
    Role = var.instance_names[count.index]
  }
}

# ===========================================
# COUNT - Subnets across AZs
# ===========================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  count = min(length(data.aws_availability_zones.available.names), 3)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
    Type = "public"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# ===========================================
# FOR_EACH - With Set
# ===========================================

resource "aws_instance" "foreach_set" {
  for_each = toset(["web", "app", "db"])

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "${var.environment}-${each.key}"
    Role = each.key
  }
}

# ===========================================
# FOR_EACH - With Map (different instance types)
# ===========================================

variable "servers" {
  description = "Map of server configurations"
  default = {
    web = {
      instance_type = "t2.micro"
      disk_size     = 20
    }
    app = {
      instance_type = "t2.small"
      disk_size     = 30
    }
    db = {
      instance_type = "t2.medium"
      disk_size     = 50
    }
  }
}

resource "aws_instance" "foreach_map" {
  for_each = var.servers

  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type

  root_block_device {
    volume_size = each.value.disk_size
  }

  tags = {
    Name         = "${var.environment}-${each.key}"
    Role         = each.key
    InstanceType = each.value.instance_type
    DiskSize     = each.value.disk_size
  }
}

# ===========================================
# FOR_EACH - Security Group Rules
# ===========================================

variable "ingress_rules" {
  description = "Ingress rules for security group"
  default = {
    ssh = {
      port        = 22
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH from internal"
    }
    http = {
      port        = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere"
    }
    https = {
      port        = 443
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    }
  }
}

resource "aws_security_group" "foreach_rules" {
  name        = "${var.environment}-foreach-sg"
  description = "Security group with for_each rules"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-foreach-sg"
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.ingress_rules

  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.foreach_rules.id
}

# ===========================================
# FOR_EACH - IAM Users
# ===========================================

variable "users" {
  description = "Map of IAM users to create"
  default = {
    alice = {
      groups = ["developers"]
      tags   = { Department = "Engineering" }
    }
    bob = {
      groups = ["developers", "admins"]
      tags   = { Department = "Engineering" }
    }
    charlie = {
      groups = ["readonly"]
      tags   = { Department = "Support" }
    }
  }
}

resource "aws_iam_user" "users" {
  for_each = var.users

  name = each.key

  tags = merge(each.value.tags, {
    ManagedBy = "terraform"
  })
}

# ===========================================
# Combining count and for_each (in different resources)
# ===========================================

# Conditional module creation with count
# resource "aws_instance" "optional" {
#   count = var.create_bastion ? 1 : 0
#   ...
# }

# Multiple configs with for_each
# resource "aws_instance" "servers" {
#   for_each = var.servers
#   ...
# }

# ===========================================
# Complex for_each with flattening
# ===========================================

variable "environments_with_servers" {
  description = "Environments and their servers"
  default = {
    dev = {
      servers = ["web", "api"]
    }
    prod = {
      servers = ["web1", "web2", "api1", "api2"]
    }
  }
}

locals {
  # Flatten the structure for for_each
  all_servers = flatten([
    for env, config in var.environments_with_servers : [
      for server in config.servers : {
        key         = "${env}-${server}"
        environment = env
        server_name = server
      }
    ]
  ])

  # Convert to map for for_each
  servers_map = { for server in local.all_servers : server.key => server }
}

resource "aws_instance" "flattened" {
  for_each = local.servers_map

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name        = each.key
    Environment = each.value.environment
    Server      = each.value.server_name
  }
}

# ===========================================
# Outputs
# ===========================================

# Count outputs
output "count_instance_ids" {
  description = "IDs of count-based instances"
  value       = aws_instance.count_basic[*].id
}

output "count_instance_ips" {
  description = "Private IPs of count-based instances"
  value       = aws_instance.count_basic[*].private_ip
}

# For_each outputs
output "foreach_instance_ids" {
  description = "Map of for_each instance names to IDs"
  value = {
    for name, instance in aws_instance.foreach_set :
    name => instance.id
  }
}

output "foreach_map_details" {
  description = "Details of for_each map instances"
  value = {
    for name, instance in aws_instance.foreach_map :
    name => {
      id           = instance.id
      private_ip   = instance.private_ip
      instance_type = instance.instance_type
    }
  }
}

# Flattened output
output "flattened_instances" {
  description = "All flattened instances"
  value = {
    for key, instance in aws_instance.flattened :
    key => instance.id
  }
}

output "iam_users" {
  description = "Created IAM users"
  value = {
    for name, user in aws_iam_user.users :
    name => user.arn
  }
}
