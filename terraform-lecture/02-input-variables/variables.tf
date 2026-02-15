# ===========================================
# Input Variables - All Types and Features
# ===========================================

# ===========================================
# STRING Variables
# ===========================================
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myapp"

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 20
    error_message = "Project name must be between 3 and 20 characters."
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.aws_region))
    error_message = "AWS region must be a valid format (e.g., us-east-1, eu-west-2)."
  }
}

# ===========================================
# NUMBER Variables
# ===========================================
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 8 && var.disk_size_gb <= 1000
    error_message = "Disk size must be between 8 and 1000 GB."
  }
}

variable "port" {
  description = "Application port"
  type        = number
  default     = 8080
}

# ===========================================
# BOOLEAN Variables
# ===========================================
variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "enable_public_ip" {
  description = "Assign public IP to instances"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

# ===========================================
# LIST Variables
# ===========================================
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "allowed_ports" {
  description = "List of allowed ingress ports"
  type        = list(number)
  default     = [22, 80, 443]
}

variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# ===========================================
# MAP Variables
# ===========================================
variable "instance_types" {
  description = "Instance types per environment"
  type        = map(string)
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.large"
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Team      = "devops"
    ManagedBy = "terraform"
  }
}

variable "ami_ids" {
  description = "AMI IDs per region"
  type        = map(string)
  default = {
    "us-east-1" = "ami-0c55b159cbfafe1f0"
    "us-west-2" = "ami-0d6621c01e8c2de2c"
    "eu-west-1" = "ami-0d8e27447ec2c8410"
  }
}

# ===========================================
# SET Variables (unique values)
# ===========================================
variable "security_groups" {
  description = "Set of security group IDs"
  type        = set(string)
  default     = []
}

# ===========================================
# OBJECT Variables (structured data)
# ===========================================
variable "instance_config" {
  description = "Instance configuration"
  type = object({
    instance_type = string
    ami_id        = string
    disk_size     = number
    encrypted     = bool
  })
  default = {
    instance_type = "t2.micro"
    ami_id        = "ami-0c55b159cbfafe1f0"
    disk_size     = 20
    encrypted     = true
  }
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    storage_gb     = number
    multi_az       = bool
    backup_days    = number
  })
  default = {
    engine         = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    storage_gb     = 20
    multi_az       = false
    backup_days    = 7
  }

  validation {
    condition     = contains(["mysql", "postgres", "mariadb"], var.database_config.engine)
    error_message = "Database engine must be mysql, postgres, or mariadb."
  }
}

# ===========================================
# TUPLE Variables (fixed-length sequence)
# ===========================================
variable "instance_specs" {
  description = "Instance specifications [name, type, count]"
  type        = tuple([string, string, number])
  default     = ["web-server", "t2.micro", 2]
}

# ===========================================
# COMPLEX/NESTED Variables
# ===========================================
variable "servers" {
  description = "Map of server configurations"
  type = map(object({
    instance_type = string
    disk_size     = number
    subnet_index  = number
    tags          = map(string)
  }))
  default = {
    web = {
      instance_type = "t2.micro"
      disk_size     = 20
      subnet_index  = 0
      tags = {
        Role = "web"
        Tier = "frontend"
      }
    }
    app = {
      instance_type = "t2.small"
      disk_size     = 30
      subnet_index  = 1
      tags = {
        Role = "app"
        Tier = "backend"
      }
    }
    db = {
      instance_type = "t2.medium"
      disk_size     = 50
      subnet_index  = 2
      tags = {
        Role = "db"
        Tier = "data"
      }
    }
  }
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH from internal"
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
    }
  ]
}

# ===========================================
# SENSITIVE Variables
# ===========================================
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true
  default     = ""
}

# ===========================================
# NULLABLE Variables
# ===========================================
variable "optional_value" {
  description = "An optional value that can be null"
  type        = string
  default     = null
  nullable    = true
}
