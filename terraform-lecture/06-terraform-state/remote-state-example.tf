# ===========================================
# Remote State Example - S3 Backend
# ===========================================
# This is an EXAMPLE - don't apply directly
# Use this as a reference for remote state setup


terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ===========================================
  # S3 BACKEND with DynamoDB Locking
  # ===========================================
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"

    # Optional: Enable versioning in S3 bucket for state history
  }
}

provider "aws" {
  region = "us-east-1"
}

# ===========================================
# Resources
# ===========================================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "remote-state-demo-vpc"
  }
}

# ===========================================
# Bootstrap Resources for Remote State
# ===========================================
# Run this FIRST to create the backend resources

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

variable "state_bucket_name" {
  description = "Name for the S3 bucket to store state"
  default     = "my-terraform-state-bucket"
}

variable "lock_table_name" {
  description = "Name for the DynamoDB table for state locking"
  default     = "terraform-state-locks"
}

# S3 Bucket for State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Purpose     = "terraform-state"
    ManagedBy   = "terraform"
  }
}

# Enable versioning for state history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Purpose     = "terraform-state-locking"
    ManagedBy   = "terraform"
  }
}

# ===========================================
# Outputs
# ===========================================

output "state_bucket_name" {
  description = "Name of the S3 bucket for state storage"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Backend configuration to use in other projects"
  value       = <<-EOT

    # Add this to your terraform block:
    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.id}"
      key            = "path/to/your/terraform.tfstate"
      region         = "us-east-1"
      encrypt        = true
      dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
    }

  EOT
}
