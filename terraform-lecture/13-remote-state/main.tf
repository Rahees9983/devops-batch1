# ===========================================
# Remote State - S3 Backend with DynamoDB Locking
# ===========================================

# ===========================================
# STEP 1: Bootstrap Resources
# Run this first to create S3 bucket and DynamoDB table
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Initially use local backend, then migrate to S3
  # backend "local" {}
}

provider "aws" {
  region = "us-east-1"
}

variable "project_name" {
  default = "terraform-state-demo"
}

variable "environment" {
  default = "dev"
}

# ===========================================
# S3 Bucket for State Storage
# ===========================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-state-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Purpose     = "terraform-state"
    Environment = var.environment
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
    bucket_key_enabled = true
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

# ===========================================
# DynamoDB Table for State Locking
# ===========================================

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Purpose     = "terraform-state-locking"
    Environment = var.environment
  }
}

# ===========================================
# Data Sources
# ===========================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

output "lock_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_config" {
  description = "Backend configuration to use"
  value       = <<-EOT

    # Add this to your terraform block after bootstrap:

    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "environments/${var.environment}/terraform.tfstate"
        region         = "${data.aws_region.current.name}"
        encrypt        = true
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
      }
    }

    # Then run: terraform init -migrate-state

  EOT
}

output "partial_backend_config" {
  description = "Partial backend config for -backend-config"
  value       = <<-EOT

    # Create a file: backend.hcl

    bucket         = "${aws_s3_bucket.terraform_state.id}"
    key            = "environments/ENV_NAME/terraform.tfstate"
    region         = "${data.aws_region.current.name}"
    encrypt        = true
    dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"

    # Then use: terraform init -backend-config=backend.hcl

  EOT
}
