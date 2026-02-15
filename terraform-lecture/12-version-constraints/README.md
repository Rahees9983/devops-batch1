# Terraform Version Constraints

## Why Version Constraints?

Version constraints ensure:
- Consistent behavior across team members
- Protection from breaking changes
- Reproducible infrastructure deployments

## Types of Version Constraints

1. **Terraform Core Version**
2. **Provider Versions**
3. **Module Versions**

---

## Terraform Core Version

### Syntax

```hcl
terraform {
  required_version = ">= 1.0.0"
}
```

### Constraint Operators

| Operator | Example | Meaning |
|----------|---------|---------|
| `=` | `= 1.0.0` | Exact version |
| `!=` | `!= 1.0.0` | Not this version |
| `>` | `> 1.0.0` | Greater than |
| `>=` | `>= 1.0.0` | Greater than or equal |
| `<` | `< 2.0.0` | Less than |
| `<=` | `<= 2.0.0` | Less than or equal |
| `~>` | `~> 1.0.0` | Pessimistic constraint |

### Pessimistic Constraint (~>)

The `~>` operator allows only the rightmost version component to increment.

```hcl
# ~> 1.0.0 allows 1.0.x but not 1.1.0
terraform {
  required_version = "~> 1.0.0"  # Allows 1.0.0, 1.0.1, ... 1.0.99
}

# ~> 1.0 allows 1.x but not 2.0
terraform {
  required_version = "~> 1.0"  # Allows 1.0, 1.1, 1.2, ... 1.99
}
```

### Combining Constraints

```hcl
terraform {
  required_version = ">= 1.0.0, < 2.0.0"  # 1.x only
}

terraform {
  required_version = ">= 1.3.0, != 1.4.0"  # 1.3+ except 1.4.0
}
```

### Examples

```hcl
# Exact version
terraform {
  required_version = "= 1.5.0"
}

# Minimum version
terraform {
  required_version = ">= 1.0.0"
}

# Range
terraform {
  required_version = ">= 1.0.0, < 2.0.0"
}

# Pessimistic - patch level
terraform {
  required_version = "~> 1.5.0"  # 1.5.x
}

# Pessimistic - minor level
terraform {
  required_version = "~> 1.5"  # 1.x where x >= 5
}
```

---

## Provider Version Constraints

### Basic Syntax

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Multiple Providers

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}
```

### Provider Source Addresses

```hcl
terraform {
  required_providers {
    # Official HashiCorp provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Third-party provider
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }

    # Community provider
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }

    # Private registry provider
    mycompany = {
      source  = "registry.mycompany.com/myorg/mycloud"
      version = ">= 1.0.0"
    }
  }
}
```

---

## Dependency Lock File

### What is .terraform.lock.hcl?

The lock file records the exact provider versions used, ensuring consistent deployments.

```hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:ltxyuBWIy9cq0kIKDJH1jeWJy/y7XJLjS4QchoLCY3Y=",
    "zh:0cdb9c2083bf0902442384f7309367791e4640581652dda456f2d6d7abf0de8d",
    ...
  ]
}
```

### Lock File Commands

```bash
# Initialize and create/update lock file
terraform init

# Upgrade providers within constraints
terraform init -upgrade

# Update lock file for specific platforms
terraform providers lock \
  -platform=windows_amd64 \
  -platform=darwin_amd64 \
  -platform=linux_amd64
```

### Platform-Specific Hashes

```bash
# Lock for multiple platforms (useful for teams)
terraform providers lock \
  -platform=darwin_amd64 \
  -platform=darwin_arm64 \
  -platform=linux_amd64 \
  -platform=windows_amd64
```

### Best Practices for Lock Files

1. **Commit to version control**: Ensures consistent versions across team
2. **Review changes**: Check lock file diffs during code review
3. **Update regularly**: Keep providers updated for security patches

---

## Module Version Constraints

### Terraform Registry Modules

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"  # Exact version

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"  # Any 19.x version

  cluster_name = "my-cluster"
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = ">= 5.0.0, < 6.0.0"  # 5.x range

  identifier = "my-database"
}
```

### Git Source with Ref

```hcl
# Specific tag
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.0.0"
}

# Specific branch
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=main"
}

# Specific commit
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=abc1234"
}

# SSH with tag
module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git?ref=v5.0.0"
}
```

### GitHub Source

```hcl
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.0.0"
}
```

### Local Modules (No Version)

```hcl
# Local modules don't have version constraints
module "vpc" {
  source = "./modules/vpc"
}

module "security" {
  source = "../shared/security"
}
```

---

## Complete Example

```hcl
# versions.tf
terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# main.tf
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "production"
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.environment}-web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}
```

---

## Semantic Versioning

Terraform follows semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Version Selection Strategy

```hcl
# Conservative: Exact version (most stable)
version = "= 5.31.0"

# Moderate: Patch updates only
version = "~> 5.31.0"  # Allows 5.31.x

# Flexible: Minor updates
version = "~> 5.31"  # Allows 5.x where x >= 31

# Liberal: Any version in major range (not recommended)
version = ">= 5.0.0, < 6.0.0"
```

---

## Checking Version Compatibility

```bash
# Show current Terraform version
terraform version

# Show required versions
terraform providers

# Validate version constraints
terraform validate
```

### Error Examples

```bash
# Terraform version too old
$ terraform plan
Error: Unsupported Terraform Core version

  on versions.tf line 2, in terraform:
   2:   required_version = ">= 1.5.0"

This configuration does not support Terraform version 1.3.0. To proceed,
either choose another supported Terraform version or update this version
constraint.

# Provider version not available
$ terraform init
Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider
hashicorp/aws: no available releases match the given constraints
~> 99.0
```

---

## Best Practices

1. **Always specify versions** in production configurations
2. **Use pessimistic constraints** (`~>`) for stability
3. **Pin exact versions** in critical environments
4. **Commit lock files** to version control
5. **Regularly update** providers for security patches
6. **Test updates** in lower environments first
7. **Document version requirements** in README

## Lab Exercise

1. Create a configuration with Terraform core version constraint
2. Add multiple provider version constraints
3. Use a versioned module from the Terraform Registry
4. Run `terraform init` and examine the lock file
5. Try upgrading providers with `terraform init -upgrade`
