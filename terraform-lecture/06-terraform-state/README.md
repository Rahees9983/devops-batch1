# Terraform State

## What is Terraform State?

Terraform state is a critical file that maps your configuration to real-world resources. It tracks:

- Which resources Terraform manages
- Resource metadata and attributes
- Dependencies between resources
- The current state of your infrastructure

## State File Location

By default, state is stored locally in `terraform.tfstate`:

```
my-project/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfstate     # State file
```

## State File Structure

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 5,
  "lineage": "unique-id-here",
  "outputs": {
    "instance_ip": {
      "value": "54.123.45.67",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "ami": "ami-0c55b159cbfafe1f0",
            "arn": "arn:aws:ec2:us-east-1:123456789:instance/i-1234567890abcdef",
            "id": "i-1234567890abcdef",
            "instance_type": "t2.micro",
            "public_ip": "54.123.45.67"
          }
        }
      ]
    }
  ]
}
```

## Why State is Important

### 1. Mapping Configuration to Real World

```hcl
# Configuration
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# State maps this to actual instance: i-1234567890abcdef
```

### 2. Tracking Metadata

State stores metadata like:
- Resource IDs
- Dependencies
- Provider information

### 3. Performance Optimization

Without state, Terraform would need to query the cloud provider for every resource on every plan/apply.

### 4. Syncing Team Work

Remote state allows team collaboration by providing a single source of truth.

## State Operations

### View Current State

```bash
# Show entire state
terraform show

# Show state as JSON
terraform show -json

# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web
```

### State File Backup

Terraform automatically creates `terraform.tfstate.backup` before modifying state.

## State and terraform plan

When you run `terraform plan`, Terraform:

1. Reads the state file
2. Refreshes state (queries real infrastructure)
3. Compares configuration to state
4. Shows what changes are needed

```
# Configuration says:
resource "aws_instance" "web" {
  instance_type = "t2.small"  # Changed from t2.micro
}

# State shows:
# instance_type = "t2.micro"

# Plan will show:
# ~ instance_type = "t2.micro" -> "t2.small"
```

## State Locking

State locking prevents concurrent modifications:

```hcl
# When using S3 backend with DynamoDB
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"  # Enables locking
    encrypt        = true
  }
}
```

When locked:
```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        12345678-1234-1234-1234-123456789012
  Path:      my-terraform-state/prod/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.5.0
  Created:   2024-01-15 10:30:00.123456789 +0000 UTC
```

### Force Unlock (Use with Caution!)

```bash
terraform force-unlock LOCK_ID
```

## Sensitive Data in State

State may contain sensitive data:

```json
{
  "resources": [
    {
      "type": "aws_db_instance",
      "instances": [
        {
          "attributes": {
            "password": "supersecretpassword"  # Stored in plain text!
          }
        }
      ]
    }
  ]
}
```

### Protecting State

1. **Use remote state** with encryption
2. **Restrict access** to state files
3. **Enable encryption at rest**
4. **Use state encryption** (Terraform Cloud/Enterprise)

## Local vs Remote State

### Local State

```
Pros:
- Simple setup
- No external dependencies
- Good for learning/testing

Cons:
- No collaboration
- No locking
- Risk of data loss
- Sensitive data on local disk
```

### Remote State

```
Pros:
- Team collaboration
- State locking
- Encryption
- Versioning
- Backup

Cons:
- Additional setup
- Potential costs
- Network dependency
```

## State Drift

State drift occurs when real infrastructure differs from state:

### Causes of Drift:
1. Manual changes in cloud console
2. Changes by other tools
3. Auto-scaling events
4. External processes

### Detecting Drift:

```bash
# Refresh state and show changes
terraform plan -refresh-only

# Output will show:
# Note: Objects have changed outside of Terraform

# aws_instance.web:
#   ~ tags = {
#       + "ManualTag" = "added-manually"
#     }
```

### Handling Drift:

```bash
# Option 1: Update state to match reality
terraform apply -refresh-only

# Option 2: Update infrastructure to match config
terraform apply
```

## State File Best Practices

1. **Never edit state manually** - Use terraform state commands
2. **Always use remote state** for team projects
3. **Enable state locking** to prevent conflicts
4. **Encrypt state** at rest and in transit
5. **Back up state** regularly
6. **Use separate state** per environment
7. **Restrict access** to state files

## Complete Example with State Inspection

```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "web-server"
  }
}
```

### State Commands Demo

```bash
# Initialize and apply
terraform init
terraform apply

# List resources in state
terraform state list
# Output:
# aws_instance.web
# aws_subnet.public
# aws_vpc.main

# Show specific resource
terraform state show aws_instance.web
# Output:
# resource "aws_instance" "web" {
#     ami                    = "ami-0c55b159cbfafe1f0"
#     arn                    = "arn:aws:ec2:us-east-1:123456789:instance/i-abc123"
#     id                     = "i-abc123"
#     instance_type          = "t2.micro"
#     ...
# }

# Pull state to view as JSON
terraform state pull | jq '.resources[].type'
# Output:
# "aws_vpc"
# "aws_subnet"
# "aws_instance"
```

## Lab Exercise

1. Create a simple infrastructure with state
2. List and inspect state resources
3. Make a manual change in the cloud console
4. Run `terraform plan` to detect drift
5. Resolve the drift using appropriate method
