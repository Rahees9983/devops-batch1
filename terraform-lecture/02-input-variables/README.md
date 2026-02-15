# Terraform Input Variables

## What are Input Variables?

Input variables serve as parameters for a Terraform module, allowing customization without altering the module's source code. They make your configurations reusable and flexible.

## Variable Declaration

### Basic Syntax

```hcl
# variables.tf
variable "variable_name" {
  description = "Description of the variable"
  type        = string
  default     = "default_value"
}
```

## Variable Types

### Primitive Types

```hcl
# String
variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "my-instance"
}


variable "we"
{
  
}

# Number
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

# Boolean
variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}
```

### Complex Types

```hcl
# List
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Map
variable "instance_tags" {
  description = "Tags to apply to instances"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "demo"
  }
}

# Set (unique values only)
variable "allowed_ports" {
  description = "Set of allowed ports"
  type        = set(number)
  default     = [22, 80, 443]
}

# Object (structured data)
variable "instance_config" {
  description = "Instance configuration"
  type = object({
    instance_type = string
    ami           = string
    tags          = map(string)
  })
  default = {
    instance_type = "t2.micro"
    ami           = "ami-0c55b159cbfafe1f0"
    tags = {
      Name = "default"
    }
  }
}

# Tuple (fixed-length sequence)
variable "instance_specs" {
  description = "Instance specifications [name, type, count]"
  type        = tuple([string, string, number])
  default     = ["web-server", "t2.micro", 3]
}
```

## Ways to Assign Variable Values

### 1. Default Values

```hcl
variable "region" {
  default = "us-east-1"
}
```

### 2. Command Line Flags

```bash
terraform apply -var="region=us-west-2"
terraform apply -var="instance_count=5" -var="enable_monitoring=true"
```

### 3. Variable Definition Files (terraform.tfvars)

```hcl
# terraform.tfvars
region           = "us-west-2"
instance_count   = 3
enable_monitoring = true

instance_tags = {
  Environment = "production"
  Team        = "devops"
}

availability_zones = [
  "us-west-2a",
  "us-west-2b"
]
```

### 4. Auto-loaded Variable Files

Terraform automatically loads:
- `terraform.tfvars`
- `terraform.tfvars.json`
- `*.auto.tfvars`
- `*.auto.tfvars.json`

```hcl
# prod.auto.tfvars
environment = "production"
instance_type = "t3.large"
```

### 5. Environment Variables

```bash
export TF_VAR_region="us-west-2"
export TF_VAR_instance_count=5
terraform apply
```

### 6. Specify Variable File with -var-file

```bash
terraform apply -var-file="prod.tfvars"
terraform apply -var-file="staging.tfvars"
```

## Variable Validation

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}
```

## Sensitive Variables

```hcl
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true
}
```

When a variable is marked as `sensitive`:
- Its value won't be shown in CLI output
- It won't appear in plan output
- Still stored in state file (encrypt your state!)

## Nullable Variables

```hcl
variable "optional_tag" {
  description = "Optional tag value"
  type        = string
  default     = null
  nullable    = true
}
```

## Using Variables in Resources

```hcl
# variables.tf
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_name" {
  type    = string
  default = "my-instance"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
  }
}

# main.tf
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type

  tags = merge(var.tags, {
    Name = var.instance_name
  })
}
```

## Variable Precedence (Lowest to Highest)

1. Default values in variable declaration
2. Environment variables (TF_VAR_*)
3. terraform.tfvars file
4. terraform.tfvars.json file
5. *.auto.tfvars or *.auto.tfvars.json files
6. -var and -var-file command line options

## Complete Example

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_config" {
  description = "EC2 instance configuration"
  type = object({
    instance_type = string
    volume_size   = number
  })
  default = {
    instance_type = "t2.micro"
    volume_size   = 20
  }
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# main.tf
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_config.instance_type
  subnet_id     = aws_subnet.public[0].id

  root_block_device {
    volume_size = var.instance_config.volume_size
  }

  tags = {
    Name        = "${var.environment}-app-server"
    Environment = var.environment
  }
}
```

## Lab Exercise

Create a Terraform configuration with:
1. Variables for instance type, count, and environment
2. Validation rules for environment variable
3. A tfvars file for production settings
4. Use variables to create EC2 instances
