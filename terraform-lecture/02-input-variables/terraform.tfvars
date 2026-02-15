# ===========================================
# Terraform Variables File (terraform.tfvars)
# ===========================================
# This file is automatically loaded by Terraform
# Other files like prod.tfvars must be specified with -var-file

# String variables
environment  = "dev"
project_name = "webapp"
aws_region   = "us-east-1"

# Number variables
instance_count = 2
disk_size_gb   = 30
port           = 8080

# Boolean variables
enable_monitoring = true
enable_public_ip  = true
enable_encryption = true

# List variables
availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

allowed_ports = [22, 80, 443, 8080]

# Map variables
common_tags = {
  Team        = "devops"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
  Application = "webapp"
}

instance_types = {
  dev     = "t2.micro"
  staging = "t2.small"
  prod    = "t2.large"
}

# Object variable
instance_config = {
  instance_type = "t2.micro"
  ami_id        = "ami-0c55b159cbfafe1f0"
  disk_size     = 25
  encrypted     = true
}

database_config = {
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  storage_gb     = 30
  multi_az       = false
  backup_days    = 7
}

# Complex nested variable
servers = {
  web = {
    instance_type = "t2.micro"
    disk_size     = 20
    subnet_index  = 0
    tags = {
      Role = "web"
      Tier = "frontend"
    }
  }
  api = {
    instance_type = "t2.small"
    disk_size     = 30
    subnet_index  = 1
    tags = {
      Role = "api"
      Tier = "backend"
    }
  }
}

# List of objects
ingress_rules = [
  {
    port        = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH from internal networks"
  },
  {
    port        = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  },
  {
    port        = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  },
  {
    port        = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "App port from internal"
  }
]
