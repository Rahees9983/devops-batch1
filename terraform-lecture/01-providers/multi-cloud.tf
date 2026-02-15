# ===========================================
# Multi-Cloud Provider Example
# ===========================================
# This example shows how to use multiple cloud providers
# in the same Terraform configuration

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ===========================================
# AWS Provider Configuration
# ===========================================
provider "aws" {
  region = var.aws_region

  # Using environment variables for credentials:
  # AWS_ACCESS_KEY_ID
  # AWS_SECRET_ACCESS_KEY

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ===========================================
# Azure Provider Configuration
# ===========================================
provider "azurerm" {
  features {}

  # Using environment variables for credentials:
  # ARM_CLIENT_ID
  # ARM_CLIENT_SECRET
  # ARM_SUBSCRIPTION_ID
  # ARM_TENANT_ID
}

# ===========================================
# Google Cloud Provider Configuration
# ===========================================
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  # Using environment variables for credentials:
  # GOOGLE_APPLICATION_CREDENTIALS (path to service account JSON)
}

# ===========================================
# Variables
# ===========================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = "my-gcp-project"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# ===========================================
# AWS Resources
# ===========================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-aws-vpc"
  }
}

# ===========================================
# Azure Resources
# ===========================================
resource "azurerm_resource_group" "main" {
  name     = "${var.environment}-azure-rg"
  location = "East US"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-azure-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ===========================================
# GCP Resources
# ===========================================
resource "google_compute_network" "main" {
  name                    = "${var.environment}-gcp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.environment}-gcp-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.gcp_region
  network       = google_compute_network.main.id
}

# ===========================================
# Outputs
# ===========================================
output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "gcp_network_id" {
  description = "GCP VPC Network ID"
  value       = google_compute_network.main.id
}
