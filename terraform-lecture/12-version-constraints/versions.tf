# ===========================================
# Version Constraints - Complete Examples
# ===========================================

terraform {
  # ===========================================
  # Terraform Core Version Constraint
  # ===========================================

  # Minimum version
  # required_version = ">= 1.0.0"

  # Exact version
  # required_version = "= 1.5.0"

  # Pessimistic constraint (patch level)
  # required_version = "~> 1.5.0"  # Allows 1.5.x

  # Pessimistic constraint (minor level)
  # required_version = "~> 1.5"  # Allows 1.x where x >= 5

  # Range
  required_version = ">= 1.3.0, < 2.0.0"

  # ===========================================
  # Provider Version Constraints
  # ===========================================

  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Any 5.x version
    }

    # Azure Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"  # 3.x range
    }

    # Google Cloud Provider
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    # Kubernetes Provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"  # Minimum version
    }

    # Random Provider
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

    # Null Provider
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }

    # Local Provider
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }

    # TLS Provider
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ===========================================
# Provider Configurations
# ===========================================

provider "aws" {
  region = "us-east-1"
}

provider "random" {}

# ===========================================
# Resources demonstrating version features
# ===========================================

resource "random_id" "example" {
  byte_length = 4
}

resource "aws_s3_bucket" "example" {
  bucket = "version-demo-${random_id.example.hex}"

  tags = {
    Name = "version-demo"
  }
}

# ===========================================
# Outputs
# ===========================================

output "terraform_version_info" {
  description = "Information about version constraints"
  value       = <<-EOT

    VERSION CONSTRAINT OPERATORS:
    =============================

    =  (exact)     : = 1.5.0     -> Only 1.5.0
    != (not equal) : != 1.5.0    -> Any except 1.5.0
    >  (greater)   : > 1.5.0     -> Greater than 1.5.0
    >= (greater/eq): >= 1.5.0    -> 1.5.0 or greater
    <  (less)      : < 2.0.0     -> Less than 2.0.0
    <= (less/eq)   : <= 2.0.0    -> 2.0.0 or less
    ~> (pessimist) : ~> 1.5.0    -> 1.5.x (rightmost can increment)
                   : ~> 1.5      -> 1.x (where x >= 5)

    COMMON PATTERNS:
    ================

    Exact version (most strict):
      version = "= 5.31.0"

    Patch updates only:
      version = "~> 5.31.0"    # 5.31.0, 5.31.1, 5.31.2, etc.

    Minor updates:
      version = "~> 5.31"      # 5.31, 5.32, 5.33, etc.

    Range:
      version = ">= 5.0.0, < 6.0.0"  # Any 5.x

    Multiple constraints:
      version = ">= 5.0.0, != 5.5.0"  # 5.x except 5.5.0

  EOT
}

output "bucket_name" {
  value = aws_s3_bucket.example.id
}
