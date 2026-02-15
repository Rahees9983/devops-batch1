# ===========================================
# Terraform Providers Examples
# ===========================================

# Example 1: AWS Provider with Version Constraint
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default AWS Provider
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "provider-demo"
    }
  }
}

# AWS Provider with Alias for different region
provider "aws" {
  alias  = "west"
  region = "us-west-2"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "provider-demo"
    }
  }
}

# AWS Provider with Alias for EU region
provider "aws" {
  alias  = "eu"
  region = "eu-west-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "provider-demo"
    }
  }
}

# ===========================================
# Resources using different providers
# ===========================================

# S3 Bucket in US-EAST-1 (default provider)
resource "aws_s3_bucket" "east_bucket" {
  bucket = "demo-provider-east-${random_id.bucket_suffix.hex}"

  tags = {
    Name   = "East Bucket"
    Region = "us-east-1"
  }
}

# S3 Bucket in US-WEST-2 (using alias)
resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west
  bucket   = "demo-provider-west-${random_id.bucket_suffix.hex}"

  tags = {
    Name   = "West Bucket"
    Region = "us-west-2"
  }
}

# S3 Bucket in EU-WEST-1 (using alias)
resource "aws_s3_bucket" "eu_bucket" {
  provider = aws.eu
  bucket   = "demo-provider-eu-${random_id.bucket_suffix.hex}"

  tags = {
    Name   = "EU Bucket"
    Region = "eu-west-1"
  }
}

# Random provider for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ===========================================
# Outputs
# ===========================================

output "east_bucket_name" {
  description = "Name of the S3 bucket in us-east-1"
  value       = aws_s3_bucket.east_bucket.id
}

output "west_bucket_name" {
  description = "Name of the S3 bucket in us-west-2"
  value       = aws_s3_bucket.west_bucket.id
}

output "eu_bucket_name" {
  description = "Name of the S3 bucket in eu-west-1"
  value       = aws_s3_bucket.eu_bucket.id
}
