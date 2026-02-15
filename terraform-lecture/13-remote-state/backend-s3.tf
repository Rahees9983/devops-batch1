# ===========================================
# Remote State with S3 Backend - Complete Example
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ===========================================
  # S3 BACKEND CONFIGURATION
  # ===========================================
  # Uncomment and configure to use S3 backend

  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "environments/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-locks"
  #
  #   # Optional: Use a specific profile
  #   # profile = "terraform"
  #
  #   # Optional: Use workspace prefix
  #   # workspace_key_prefix = "workspaces"
  # }
}

provider "aws" {
  region = "us-east-1"
}

# ===========================================
# BOOTSTRAP: Create Backend Resources
# Run this FIRST with local state,
# then migrate to S3 backend
# ===========================================

variable "state_bucket_name" {
  description = "Name for the S3 bucket to store state"
  type        = string
  default     = "demo-terraform-state"
}

variable "lock_table_name" {
  description = "Name for the DynamoDB table for locking"
  type        = string
  default     = "terraform-state-locks"
}

# S3 Bucket for State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.state_bucket_name}-${random_id.bucket.hex}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "Terraform State Bucket"
    Purpose   = "terraform-state"
    ManagedBy = "terraform"
  }
}

resource "random_id" "bucket" {
  byte_length = 4
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Block public access
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
    Name      = "Terraform State Lock Table"
    Purpose   = "terraform-state-locking"
    ManagedBy = "terraform"
  }
}

# ===========================================
# OUTPUTS
# ===========================================

output "state_bucket_name" {
  description = "S3 bucket name for state storage"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name for locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "lock_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_configuration" {
  description = "Backend configuration for other projects"
  value       = <<-EOT

    # Add this to your terraform block:

    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "path/to/terraform.tfstate"
        region         = "us-east-1"
        encrypt        = true
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
      }
    }

    # To migrate from local to S3:
    # 1. Add the backend block above
    # 2. Run: terraform init -migrate-state

  EOT
}

output "state_locking_info" {
  description = "Information about state locking"
  value       = <<-EOT

    STATE LOCKING:
    ==============

    When you run terraform apply/plan:
    1. Terraform acquires a lock in DynamoDB
    2. Lock contains: ID, Who, When, Operation
    3. Other users see "state is locked" error
    4. Lock is released when operation completes

    FORCE UNLOCK (emergency only):
    terraform force-unlock <LOCK_ID>

    DISABLE LOCKING (not recommended):
    terraform apply -lock=false

    SET LOCK TIMEOUT:
    terraform apply -lock-timeout=10m

  EOT
}
