# Terraform Modules

## What are Modules?

Modules are reusable, self-contained packages of Terraform configurations. They help:

- **Organize** code into logical components
- **Encapsulate** complexity
- **Reuse** configurations across projects
- **Standardize** infrastructure patterns

## Module Structure

```
my-module/
├── main.tf          # Main resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider requirements
├── README.md        # Documentation
├── examples/        # Example usage
│   └── basic/
│       └── main.tf
└── modules/         # Nested modules (optional)
    └── submodule/
```

---

## Creating a Module

### Simple VPC Module

```hcl
# modules/vpc/variables.tf
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-${count.index + 1}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-private-${count.index + 1}"
    Type = "private"
  })
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-nat"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-private-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

```hcl
# modules/vpc/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ip" {
  description = "Public IP of NAT Gateway"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}
```

```hcl
# modules/vpc/versions.tf
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}
```

---

## Using Modules

### Local Module

```hcl
# main.tf
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = "production"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway   = true

  tags = {
    Environment = "production"
    Project     = "myapp"
  }
}

# Access module outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}
```

### Terraform Registry Module

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### GitHub Module

```hcl
# HTTPS
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.0.0"
}

# SSH
module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git?ref=v5.0.0"
}
```

### S3 Module

```hcl
module "vpc" {
  source = "s3::https://s3-us-east-1.amazonaws.com/mybucket/vpc-module.zip"
}
```

---

## Module Best Practices

### 1. Use Variables for Everything Configurable

```hcl
# Good - configurable
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

resource "aws_instance" "main" {
  instance_type = var.instance_type
}

# Bad - hardcoded
resource "aws_instance" "main" {
  instance_type = "t2.micro"
}
```

### 2. Provide Sensible Defaults

```hcl
variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false  # Sensible default
}
```

### 3. Validate Inputs

```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 4. Output Everything Useful

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}
```

### 5. Document with README

```markdown
# VPC Module

Creates a VPC with public and private subnets.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "production"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vpc_name | Name of the VPC | string | - |
| vpc_cidr | CIDR block | string | "10.0.0.0/16" |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | IDs of public subnets |
```

---

## Advanced Module Patterns

### Module Composition

```hcl
# Root module composes multiple child modules
module "vpc" {
  source = "./modules/vpc"
  # ...
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "database" {
  source     = "./modules/database"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  security_group_id = module.security.db_security_group_id
}

module "application" {
  source     = "./modules/application"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  db_host    = module.database.endpoint
}
```

### Module with for_each

```hcl
variable "environments" {
  type = map(object({
    vpc_cidr     = string
    instance_type = string
  }))
  default = {
    dev = {
      vpc_cidr     = "10.0.0.0/16"
      instance_type = "t2.micro"
    }
    prod = {
      vpc_cidr     = "10.1.0.0/16"
      instance_type = "t2.small"
    }
  }
}

module "environment" {
  source   = "./modules/environment"
  for_each = var.environments

  environment   = each.key
  vpc_cidr      = each.value.vpc_cidr
  instance_type = each.value.instance_type
}

output "environment_vpc_ids" {
  value = { for k, v in module.environment : k => v.vpc_id }
}
```

### Module with count

```hcl
variable "create_vpc" {
  type    = bool
  default = true
}

module "vpc" {
  source = "./modules/vpc"
  count  = var.create_vpc ? 1 : 0

  vpc_name = "my-vpc"
}

output "vpc_id" {
  value = var.create_vpc ? module.vpc[0].vpc_id : null
}
```

### Passing Providers to Modules

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

module "vpc_east" {
  source = "./modules/vpc"
  # Uses default provider
}

module "vpc_west" {
  source = "./modules/vpc"
  providers = {
    aws = aws.west
  }
}
```

---

## Complete Example: Three-Tier Application

```
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    ├── vpc/
    ├── security/
    ├── database/
    └── application/
```

```hcl
# main.tf
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name             = "${var.project}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.environment == "prod"

  tags = local.common_tags
}

module "security" {
  source = "./modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment

  tags = local.common_tags
}

module "database" {
  source = "./modules/database"

  identifier     = "${var.project}-${var.environment}-db"
  instance_class = var.db_instance_class
  db_name        = var.project
  username       = var.db_username
  password       = var.db_password

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security.db_security_group_id

  tags = local.common_tags
}

module "application" {
  source = "./modules/application"

  name           = "${var.project}-${var.environment}"
  instance_type  = var.app_instance_type
  instance_count = var.app_instance_count

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security.app_security_group_id

  db_host = module.database.endpoint
  db_name = var.project

  tags = local.common_tags
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

```hcl
# outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = module.database.endpoint
}

output "application_url" {
  description = "Application URL"
  value       = module.application.load_balancer_dns
}
```

---

## Module Publishing

### Publish to Terraform Registry

1. Create a GitHub repo named `terraform-<PROVIDER>-<NAME>`
2. Add required files (main.tf, variables.tf, outputs.tf)
3. Tag releases with semantic versioning (v1.0.0)
4. Sign in to registry.terraform.io with GitHub
5. Publish the module

### Private Module Registry

```hcl
# Terraform Cloud/Enterprise
module "vpc" {
  source  = "app.terraform.io/my-org/vpc/aws"
  version = "1.0.0"
}

# Self-hosted registry
module "vpc" {
  source  = "registry.mycompany.com/my-org/vpc/aws"
  version = "1.0.0"
}
```

---

## Lab Exercise

1. Create a reusable EC2 module with configurable instance type and tags
2. Create a VPC module with public/private subnets
3. Use your modules in a root configuration
4. Try using a module from the Terraform Registry
5. Create multiple environments using module for_each
