# Terraform Providers

## What is a Provider?

A **Provider** is a plugin that Terraform uses to interact with cloud platforms, SaaS providers, and other APIs. Providers are responsible for understanding API interactions and exposing resources.

## Key Concepts

- Providers are distributed separately from Terraform itself
- Each provider adds a set of resource types and/or data sources
- Providers are downloaded during `terraform init`
- Multiple instances of the same provider can be configured using aliases

## Provider Configuration

### Basic AWS Provider

```hcl
# main.tf
terraform {
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

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

### Multiple Provider Configurations (Aliases)

```hcl
# Configure default provider
provider "aws" {
  region = "us-east-1"
}

# Configure alternate provider with alias
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Use default provider
resource "aws_instance" "east_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# Use aliased provider
resource "aws_instance" "west_instance" {
  provider      = aws.west
  ami           = "ami-0d6621c01e8c2de2c"
  instance_type = "t2.micro"
}
```

### Azure Provider Example

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "your-subscription-id"
  tenant_id       = "your-tenant-id"
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}
```

### Google Cloud Provider Example

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "my-project-id"
  region  = "us-central1"
}

resource "google_compute_instance" "example" {
  name         = "example-instance"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}
```

### Kubernetes Provider Example

```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  alias = dev-k8s-cluster
  # OR use config_context for specific context
  # config_context = "my-cluster"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  alias = prod-k8s-cluster
  # OR use config_context for specific context
  # config_context = "my-cluster"
}

resource "kubernetes_namespace" "example" {
  provider = kubernetes.prod-k8s-cluster
  metadata {
    name = "my-namespace"
  }
}
```

## Provider Authentication Methods

### AWS Authentication Options

```hcl
# Option 1: Static credentials (NOT recommended for production)
provider "aws" {
  region     = "us-east-1"
  access_key = "your-access-key"
  secret_key = "your-secret-key"
}

# Option 2: Environment variables (Recommended)
# Export these before running terraform:
# export AWS_ACCESS_KEY_ID="your-access-key"
# export AWS_SECRET_ACCESS_KEY="your-secret-key"
# export AWS_REGION="us-east-1"

provider "aws" {}

# Option 3: Shared credentials file
provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

# Option 4: IAM Role (for EC2 instances)
provider "aws" {
  region = "us-east-1"
  # Automatically uses instance profile
}

# Option 5: Assume Role
provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/MyRole"
    session_name = "terraform-session"
  }
}
```

## Popular Providers

| Provider | Source | Description |
|----------|--------|-------------|
| AWS | hashicorp/aws | Amazon Web Services |
| Azure | hashicorp/azurerm | Microsoft Azure |
| GCP | hashicorp/google | Google Cloud Platform |
| Kubernetes | hashicorp/kubernetes | Kubernetes clusters |
| Helm | hashicorp/helm | Helm charts |
| Docker | kreuzwerker/docker | Docker containers |
| GitHub | integrations/github | GitHub resources |
| Vault | hashicorp/vault | HashiCorp Vault |

## Best Practices

1. **Always pin provider versions** to avoid unexpected changes
2. **Use environment variables** for credentials instead of hardcoding
3. **Use provider aliases** for multi-region deployments
4. **Document provider requirements** in your README

## Lab Exercise

Create a Terraform configuration that:
1. Uses the AWS provider
2. Creates an S3 bucket
3. Uses a provider alias for a different region
4. Creates another S3 bucket in the alternate region

```hcl
# lab/main.tf
terraform {
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

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "east_bucket" {
  bucket = "my-unique-bucket-east-12345"
}

resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west
  bucket   = "my-unique-bucket-west-12345"
}
```
