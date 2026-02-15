# Terraform Workspaces

## What are Workspaces?

Workspaces allow you to manage multiple distinct sets of infrastructure resources using the same Terraform configuration. Each workspace has its own state file.

## Use Cases

1. **Environment separation** (dev, staging, prod)
2. **Feature branches** (testing changes in isolation)
3. **Multi-tenant deployments**
4. **Regional deployments**

---

## Workspace Commands

### List Workspaces

```bash
terraform workspace list

# Output:
#   default
# * dev
#   staging
#   prod
```

### Show Current Workspace

```bash
terraform workspace show

# Output:
# dev
```

### Create New Workspace

```bash
terraform workspace new staging

# Output:
# Created and switched to workspace "staging"!
```

### Select Workspace

```bash
terraform workspace select prod

# Output:
# Switched to workspace "prod".
```

### Delete Workspace

```bash
# Must switch away first
terraform workspace select default
terraform workspace delete staging

# Output:
# Deleted workspace "staging"!
```

---

## terraform.workspace Variable

Access the current workspace name in your configuration.

```hcl
# Reference current workspace
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name        = "web-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

# Workspace in resource names
resource "aws_s3_bucket" "data" {
  bucket = "myapp-${terraform.workspace}-data"
}
```

---

## Workspace-Based Configuration

### Conditional Values

```hcl
locals {
  environment = terraform.workspace

  # Instance type per workspace
  instance_type = {
    default = "t2.micro"
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.large"
  }

  # Instance count per workspace
  instance_count = {
    default = 1
    dev     = 1
    staging = 2
    prod    = 3
  }
}

resource "aws_instance" "web" {
  count         = lookup(local.instance_count, terraform.workspace, 1)
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = lookup(local.instance_type, terraform.workspace, "t2.micro")

  tags = {
    Name        = "${local.environment}-web-${count.index + 1}"
    Environment = local.environment
  }
}
```

### Workspace Variables File

```hcl
# variables.tf
variable "workspace_config" {
  type = map(object({
    instance_type  = string
    instance_count = number
    enable_backup  = bool
  }))
  default = {
    default = {
      instance_type  = "t2.micro"
      instance_count = 1
      enable_backup  = false
    }
    dev = {
      instance_type  = "t2.micro"
      instance_count = 1
      enable_backup  = false
    }
    staging = {
      instance_type  = "t2.small"
      instance_count = 2
      enable_backup  = true
    }
    prod = {
      instance_type  = "t2.large"
      instance_count = 3
      enable_backup  = true
    }
  }
}

# main.tf
locals {
  config = var.workspace_config[terraform.workspace]
}

resource "aws_instance" "web" {
  count         = local.config.instance_count
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = local.config.instance_type

  tags = {
    Name        = "${terraform.workspace}-web-${count.index + 1}"
    Environment = terraform.workspace
    Backup      = local.config.enable_backup
  }
}
```

---

## State Storage with Workspaces

### Local Backend

Each workspace creates a separate state file:

```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

### S3 Backend with Workspaces

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "app/terraform.tfstate"
    region = "us-east-1"
  }
}
```

State files are stored with workspace prefix:

```
s3://my-terraform-state/
├── env:/dev/app/terraform.tfstate
├── env:/staging/app/terraform.tfstate
├── env:/prod/app/terraform.tfstate
└── app/terraform.tfstate  (default workspace)
```

### Custom Key Per Workspace

```hcl
terraform {
  backend "s3" {
    bucket               = "my-terraform-state"
    key                  = "terraform.tfstate"
    region               = "us-east-1"
    workspace_key_prefix = "environments"
  }
}
```

Results in:
```
s3://my-terraform-state/
├── environments/dev/terraform.tfstate
├── environments/staging/terraform.tfstate
└── environments/prod/terraform.tfstate
```

---

## Complete Example

### Directory Structure

```
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

### Configuration Files

```hcl
# versions.tf
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "myapp/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

```hcl
# variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "myapp"
}

variable "environments" {
  description = "Environment-specific configuration"
  type = map(object({
    vpc_cidr       = string
    instance_type  = string
    instance_count = number
    enable_nat     = bool
  }))
  default = {
    dev = {
      vpc_cidr       = "10.0.0.0/16"
      instance_type  = "t2.micro"
      instance_count = 1
      enable_nat     = false
    }
    staging = {
      vpc_cidr       = "10.1.0.0/16"
      instance_type  = "t2.small"
      instance_count = 2
      enable_nat     = true
    }
    prod = {
      vpc_cidr       = "10.2.0.0/16"
      instance_type  = "t2.large"
      instance_count = 3
      enable_nat     = true
    }
  }
}
```

```hcl
# main.tf
provider "aws" {
  region = var.region
}

locals {
  environment = terraform.workspace
  config      = lookup(var.environments, terraform.workspace, var.environments["dev"])

  common_tags = {
    Project     = var.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Workspace   = terraform.workspace
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = local.config.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-vpc"
  })
}

# Subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.config.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-public-${count.index + 1}"
  })
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.config.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-private-${count.index + 1}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-igw"
  })
}

# NAT Gateway (conditional)
resource "aws_eip" "nat" {
  count  = local.config.enable_nat ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  count         = local.config.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-nat"
  })
}

# Security Group
resource "aws_security_group" "web" {
  name        = "${var.project}-${local.environment}-web-sg"
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-web-sg"
  })
}

# EC2 Instances
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  count                  = local.config.instance_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = local.config.instance_type
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = merge(local.common_tags, {
    Name = "${var.project}-${local.environment}-web-${count.index + 1}"
  })
}
```

```hcl
# outputs.tf
output "workspace" {
  description = "Current workspace"
  value       = terraform.workspace
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "EC2 instance public IPs"
  value       = aws_instance.web[*].public_ip
}
```

### Workflow

```bash
# Initialize
terraform init

# Create and switch to dev workspace
terraform workspace new dev
terraform plan
terraform apply

# Create and switch to staging workspace
terraform workspace new staging
terraform plan
terraform apply

# Create and switch to prod workspace
terraform workspace new prod
terraform plan
terraform apply

# Switch between workspaces
terraform workspace select dev
terraform plan  # Shows dev resources

terraform workspace select prod
terraform plan  # Shows prod resources
```

---

## Workspaces vs Directories

### Workspace Approach

```
project/
├── main.tf
├── variables.tf
└── outputs.tf

# Same code, different state per workspace
terraform workspace select dev && terraform apply
terraform workspace select prod && terraform apply
```

### Directory Approach

```
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   └── backend.tf
├── staging/
│   ├── main.tf
│   ├── variables.tf
│   └── backend.tf
└── prod/
    ├── main.tf
    ├── variables.tf
    └── backend.tf
```

### Comparison

| Aspect | Workspaces | Directories |
|--------|------------|-------------|
| Code duplication | None | Some (or use modules) |
| State isolation | Automatic | Manual configuration |
| Flexibility | Limited | High |
| Visibility | `workspace show` | Directory structure |
| CI/CD complexity | Medium | Lower |
| Risk of applying to wrong env | Higher | Lower |

---

## Best Practices

### 1. Use Workspace-Aware Naming

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "${var.project}-${terraform.workspace}-data"
}
```

### 2. Protect Production

```hcl
# Validation to prevent mistakes
variable "confirm_production" {
  type    = bool
  default = false
}

resource "null_resource" "production_check" {
  count = terraform.workspace == "prod" && !var.confirm_production ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: Set confirm_production=true for prod' && exit 1"
  }
}
```

### 3. Default Workspace Awareness

```hcl
locals {
  # Handle default workspace gracefully
  environment = terraform.workspace == "default" ? "dev" : terraform.workspace
}
```

### 4. Document Workspace Usage

```bash
# Create a workspace management script
#!/bin/bash
# workspace.sh

case "$1" in
  dev)
    terraform workspace select dev || terraform workspace new dev
    ;;
  staging)
    terraform workspace select staging || terraform workspace new staging
    ;;
  prod)
    terraform workspace select prod || terraform workspace new prod
    echo "WARNING: You are now working with PRODUCTION!"
    ;;
  *)
    echo "Usage: $0 {dev|staging|prod}"
    exit 1
    ;;
esac

terraform workspace show
```

---

## When NOT to Use Workspaces

1. **Significantly different configurations** between environments
2. **Different providers or backends** per environment
3. **Strict access control requirements** (workspaces share the same backend)
4. **Team members unfamiliar** with workspace concept

---

## Alternatives to Workspaces

### Terragrunt

```hcl
# terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/app"
}

inputs = {
  environment = "prod"
  instance_type = "t2.large"
}
```

### Terraform Cloud Workspaces

```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      tags = ["app:myapp"]
    }
  }
}
```

---

## Lab Exercise

1. Create workspaces for dev, staging, and prod
2. Configure different instance types per workspace
3. Use `terraform.workspace` in resource names and tags
4. Deploy infrastructure to each workspace
5. Compare state files between workspaces
6. Practice switching between workspaces safely
