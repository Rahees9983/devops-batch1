# ===========================================
# Terraform Import Examples
# ===========================================

terraform {
  required_version = ">= 1.5.0"  # import blocks require 1.5+

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

variable "environment" {
  default = "demo"
}

# ===========================================
# METHOD 1: Import Block (Terraform 1.5+)
# Declarative import in configuration
# ===========================================

# Import existing VPC
# import {
#   id = "vpc-0abc123def456"
#   to = aws_vpc.imported
# }

# Import existing EC2 instance
# import {
#   id = "i-0abc123def456789"
#   to = aws_instance.imported
# }

# Import existing S3 bucket
# import {
#   id = "my-existing-bucket"
#   to = aws_s3_bucket.imported
# }

# ===========================================
# Resource configurations for imported resources
# ===========================================

# VPC configuration (match actual resource)
resource "aws_vpc" "imported" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-imported-vpc"
    Environment = var.environment
    ImportedBy  = "terraform"
  }
}

# EC2 Instance configuration
resource "aws_instance" "imported" {
  ami           = "ami-0c55b159cbfafe1f0"  # Match actual AMI
  instance_type = "t2.micro"               # Match actual type

  tags = {
    Name        = "${var.environment}-imported-instance"
    Environment = var.environment
    ImportedBy  = "terraform"
  }
}

# S3 Bucket configuration
resource "aws_s3_bucket" "imported" {
  bucket = "my-existing-bucket"

  tags = {
    Name        = "Imported Bucket"
    Environment = var.environment
    ImportedBy  = "terraform"
  }
}

# ===========================================
# METHOD 2: terraform import command
# Command-line import
# ===========================================

/*
  IMPORT COMMAND EXAMPLES:

  # Basic import
  terraform import aws_instance.web i-0abc123def456789

  # Import with count index
  terraform import 'aws_instance.web[0]' i-0abc123def456789

  # Import with for_each key
  terraform import 'aws_instance.web["server1"]' i-0abc123def456789

  # Import into module
  terraform import module.vpc.aws_vpc.main vpc-abc123

  # Import security group
  terraform import aws_security_group.web sg-abc123

  # Import S3 bucket
  terraform import aws_s3_bucket.data my-bucket-name

  # Import RDS instance
  terraform import aws_db_instance.main mydb-identifier

  # Import IAM role
  terraform import aws_iam_role.app my-role-name

  # Import IAM policy
  terraform import aws_iam_policy.custom arn:aws:iam::123456789:policy/MyPolicy

  # Import Route53 zone
  terraform import aws_route53_zone.main Z1234567890ABC

  # Import EKS cluster
  terraform import aws_eks_cluster.main my-cluster-name
*/

# ===========================================
# Generate Configuration (Terraform 1.5+)
# Auto-generate resource configuration
# ===========================================

/*
  Use -generate-config-out to auto-generate configuration:

  # Step 1: Add import block
  import {
    id = "i-0abc123def456789"
    to = aws_instance.imported
  }

  # Step 2: Generate configuration
  terraform plan -generate-config-out=generated.tf

  # Step 3: Review and adjust generated.tf
  # Step 4: Run terraform apply
*/

# ===========================================
# Complete Import Workflow Example
# ===========================================

/*
  WORKFLOW FOR IMPORTING EXISTING EC2 INSTANCE:

  1. Get instance ID from AWS Console or CLI:
     aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId'

  2. Create import block:
     import {
       id = "i-0abc123def456789"
       to = aws_instance.my_server
     }

  3. Generate configuration:
     terraform plan -generate-config-out=imported_resources.tf

  4. Review generated configuration and adjust as needed

  5. Apply the import:
     terraform apply

  6. Remove import block (optional, or leave for documentation)

  7. Verify:
     terraform plan
     # Should show "No changes"
*/

# ===========================================
# Outputs
# ===========================================

output "import_commands" {
  value = <<-EOT

    ===========================================
    TERRAFORM IMPORT COMMANDS REFERENCE
    ===========================================

    METHOD 1: Import Block (Terraform 1.5+, Recommended)
    -----------------------------------------------------

    # Add to your .tf file:
    import {
      id = "i-0abc123def456789"
      to = aws_instance.web
    }

    # Generate configuration:
    terraform plan -generate-config-out=generated.tf

    # Apply:
    terraform apply


    METHOD 2: Command Line (Legacy)
    --------------------------------

    # Step 1: Write resource config first
    resource "aws_instance" "web" {
      ami           = "ami-xxx"
      instance_type = "t2.micro"
    }

    # Step 2: Import
    terraform import aws_instance.web i-0abc123def456789

    # Step 3: Verify
    terraform plan


    COMMON RESOURCE IMPORT IDS:
    ---------------------------

    aws_instance          : Instance ID (i-xxx)
    aws_vpc               : VPC ID (vpc-xxx)
    aws_subnet            : Subnet ID (subnet-xxx)
    aws_security_group    : SG ID (sg-xxx)
    aws_s3_bucket         : Bucket name
    aws_iam_role          : Role name
    aws_iam_policy        : Policy ARN
    aws_db_instance       : DB identifier
    aws_eks_cluster       : Cluster name
    aws_route53_zone      : Zone ID

  EOT
}
