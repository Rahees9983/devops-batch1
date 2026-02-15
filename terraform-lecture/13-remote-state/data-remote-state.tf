# ===========================================
# terraform_remote_state Data Source
# Read outputs from another state file
# ===========================================

# This file demonstrates how to read outputs
# from another Terraform state file

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

# ===========================================
# Read from Remote State (S3)
# ===========================================

data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "my-terraform-state-bucket"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# ===========================================
# Read from Local State
# ===========================================

data "terraform_remote_state" "local_state" {
  backend = "local"

  config = {
    path = "../networking/terraform.tfstate"
  }
}

# ===========================================
# Use Remote State Outputs
# ===========================================

# Example: Create EC2 instance in VPC from networking state
resource "aws_instance" "app" {
  # Using outputs from remote networking state
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # Reference remote state outputs
  # subnet_id = data.terraform_remote_state.networking.outputs.private_subnet_ids[0]
  # vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.app_security_group_id]

  tags = {
    Name = "app-server"
    # VPC  = data.terraform_remote_state.networking.outputs.vpc_id
  }
}

# ===========================================
# Outputs
# ===========================================

output "remote_state_example" {
  description = "Example of using remote state"
  value       = <<-EOT

    TERRAFORM_REMOTE_STATE DATA SOURCE:
    ====================================

    1. In networking project, define outputs:

       output "vpc_id" {
         value = aws_vpc.main.id
       }

       output "private_subnet_ids" {
         value = aws_subnet.private[*].id
       }

    2. In application project, read the state:

       data "terraform_remote_state" "networking" {
         backend = "s3"
         config = {
           bucket = "my-state-bucket"
           key    = "networking/terraform.tfstate"
           region = "us-east-1"
         }
       }

    3. Use the outputs:

       resource "aws_instance" "app" {
         subnet_id = data.terraform_remote_state.networking.outputs.private_subnet_ids[0]
       }

    BACKENDS SUPPORTED:
    ===================
    - s3
    - azurerm
    - gcs
    - local
    - remote (Terraform Cloud)
    - consul
    - http

  EOT
}
