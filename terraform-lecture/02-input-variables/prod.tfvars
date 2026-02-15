# ===========================================
# Production Environment Variables
# ===========================================
# Usage: terraform apply -var-file="prod.tfvars"

environment  = "prod"
project_name = "webapp"
aws_region   = "us-east-1"

# Higher instance count for production
instance_count = 3
disk_size_gb   = 100

# Enable all monitoring and security
enable_monitoring = true
enable_public_ip  = false  # Use load balancer instead
enable_encryption = true

# Use all three AZs for high availability
availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

# Production tags
common_tags = {
  Team        = "devops"
  ManagedBy   = "terraform"
  CostCenter  = "production"
  Application = "webapp"
  Critical    = "true"
  Backup      = "daily"
}

# Larger instances for production
instance_types = {
  dev     = "t2.micro"
  staging = "t2.small"
  prod    = "t3.large"
}

# Production database config
database_config = {
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.r5.large"
  storage_gb     = 500
  multi_az       = true
  backup_days    = 30
}

# Production server configuration
servers = {
  web1 = {
    instance_type = "t3.large"
    disk_size     = 50
    subnet_index  = 0
    tags = {
      Role = "web"
      Tier = "frontend"
    }
  }
  web2 = {
    instance_type = "t3.large"
    disk_size     = 50
    subnet_index  = 1
    tags = {
      Role = "web"
      Tier = "frontend"
    }
  }
  api1 = {
    instance_type = "t3.xlarge"
    disk_size     = 100
    subnet_index  = 0
    tags = {
      Role = "api"
      Tier = "backend"
    }
  }
  api2 = {
    instance_type = "t3.xlarge"
    disk_size     = 100
    subnet_index  = 1
    tags = {
      Role = "api"
      Tier = "backend"
    }
  }
}

# More restrictive ingress for production
ingress_rules = [
  {
    port        = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH from bastion only"
  },
  {
    port        = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "HTTP from load balancer"
  },
  {
    port        = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "HTTPS from load balancer"
  }
]
