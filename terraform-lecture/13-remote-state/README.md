# Remote State and State Locking

## Why Remote State?

Local state files have limitations:
- Not shareable among team members
- No locking mechanism
- Risk of data loss
- Sensitive data on local machines

Remote state solves these problems by storing state in a shared, secure location.

## Remote State Benefits

1. **Team Collaboration**: Multiple team members can work together
2. **State Locking**: Prevents concurrent modifications
3. **Encryption**: Secure storage of sensitive data
4. **Versioning**: Track changes over time
5. **Backup**: Automatic backups in most backends

---

## Backend Configuration

### S3 Backend (AWS)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Setting Up S3 Backend

```hcl
# bootstrap/main.tf - Create backend resources first!
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### Azure Backend

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### Google Cloud Backend

```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "terraform/state"
  }
}
```

### Terraform Cloud Backend

```hcl
terraform {
  cloud {
    organization = "my-organization"

    workspaces {
      name = "my-workspace"
    }
  }
}

# Or using the backend block
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "my-organization"

    workspaces {
      name = "my-workspace"
    }
  }
}
```

### HTTP Backend

```hcl
terraform {
  backend "http" {
    address        = "http://myrest.api.com/state"
    lock_address   = "http://myrest.api.com/lock"
    unlock_address = "http://myrest.api.com/unlock"
  }
}
```

### Consul Backend

```hcl
terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    scheme  = "https"
    path    = "terraform/state"
    lock    = true
  }
}
```

---

## State Locking

State locking prevents concurrent state modifications.

### How Locking Works

```
User A: terraform apply
  1. Acquire lock ✓
  2. Read state
  3. Plan changes
  4. Apply changes
  5. Write state
  6. Release lock

User B: terraform apply (while A is running)
  1. Acquire lock ✗ (locked by User A)
  Error: state is locked
```

### Lock Error Example

```bash
$ terraform apply
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        12345678-1234-1234-1234-123456789012
  Path:      my-bucket/prod/terraform.tfstate
  Operation: OperationTypeApply
  Who:       alice@workstation
  Version:   1.5.0
  Created:   2024-01-15 10:30:00.123456789 +0000 UTC
  Info:

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

### DynamoDB Lock Table Schema

```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}
```

### Disabling Locking (Not Recommended)

```bash
# Disable locking for this operation
terraform apply -lock=false

# Set lock timeout
terraform apply -lock-timeout=10m
```

### Force Unlock (Emergency Only)

```bash
# Get lock ID from error message
terraform force-unlock LOCK_ID

# Example
terraform force-unlock 12345678-1234-1234-1234-123456789012
```

---

## Remote Backend with OSS (Alibaba Cloud)

```hcl
terraform {
  backend "oss" {
    bucket              = "terraform-state-bucket"
    prefix              = "terraform/state"
    key                 = "prod/terraform.tfstate"
    region              = "cn-hangzhou"
    tablestore_endpoint = "https://tf-oss-lock.cn-hangzhou.ots.aliyuncs.com"
    tablestore_table    = "terraform_locks"
    encrypt             = true
  }
}
```

### Setting Up OSS Backend

```hcl
# Bootstrap OSS backend resources
provider "alicloud" {
  region = "cn-hangzhou"
}

resource "alicloud_oss_bucket" "terraform_state" {
  bucket = "terraform-state-bucket"
  acl    = "private"

  versioning {
    status = "Enabled"
  }

  server_side_encryption_rule {
    sse_algorithm = "AES256"
  }
}

resource "alicloud_ots_instance" "terraform_lock" {
  name        = "tf-oss-lock"
  description = "Terraform state locking"
  accessed_by = "Any"
}

resource "alicloud_ots_table" "terraform_lock" {
  instance_name = alicloud_ots_instance.terraform_lock.name
  table_name    = "terraform_locks"
  primary_key {
    name = "LockID"
    type = "String"
  }
  time_to_live = -1
  max_version  = 1
}
```

---

## Migrating State

### Local to Remote

```bash
# 1. Add backend configuration to your config
# terraform {
#   backend "s3" { ... }
# }

# 2. Initialize with migration
terraform init -migrate-state

# Output:
# Initializing the backend...
# Do you want to copy existing state to the new backend?
#   Enter "yes" to copy and "no" to start fresh.
#
#   Enter a value: yes
# Successfully configured the backend "s3"!
```

### Remote to Local

```bash
# 1. Remove or comment out backend configuration
# 2. Run init with migration
terraform init -migrate-state
```

### Between Remote Backends

```bash
# 1. Pull current state
terraform state pull > terraform.tfstate.backup

# 2. Update backend configuration
# 3. Initialize new backend
terraform init -migrate-state -force-copy
```

---

## State Isolation Strategies

### Per-Environment State

```
infrastructure/
├── dev/
│   ├── main.tf
│   └── backend.tf  # key = "dev/terraform.tfstate"
├── staging/
│   ├── main.tf
│   └── backend.tf  # key = "staging/terraform.tfstate"
└── prod/
    ├── main.tf
    └── backend.tf  # key = "prod/terraform.tfstate"
```

### Per-Component State

```
infrastructure/
├── networking/
│   ├── main.tf
│   └── backend.tf  # key = "networking/terraform.tfstate"
├── database/
│   ├── main.tf
│   └── backend.tf  # key = "database/terraform.tfstate"
└── application/
    ├── main.tf
    └── backend.tf  # key = "application/terraform.tfstate"
```

### Combined Approach

```
infrastructure/
├── prod/
│   ├── networking/
│   │   └── backend.tf  # key = "prod/networking/terraform.tfstate"
│   ├── database/
│   │   └── backend.tf  # key = "prod/database/terraform.tfstate"
│   └── application/
│       └── backend.tf  # key = "prod/application/terraform.tfstate"
└── dev/
    ├── networking/
    │   └── backend.tf  # key = "dev/networking/terraform.tfstate"
    └── application/
        └── backend.tf  # key = "dev/application/terraform.tfstate"
```

---

## Reading Remote State (terraform_remote_state)

Access outputs from another state file:

```hcl
# networking/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

# application/main.tf
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "prod/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.networking.outputs.private_subnet_ids[0]

  tags = {
    Name = "app-server"
  }
}
```

---

## Backend Configuration with Partial Configuration

### Using -backend-config

```bash
# backend.tf
terraform {
  backend "s3" {
    # These can be provided at init time
  }
}

# Initialize with config file
terraform init -backend-config=backend.hcl

# Or with individual values
terraform init \
  -backend-config="bucket=my-terraform-state" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

### backend.hcl

```hcl
bucket         = "my-terraform-state"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-locks"
```

---

## Best Practices

1. **Enable versioning** on state storage (S3, GCS, etc.)
2. **Always enable encryption** for state files
3. **Use state locking** to prevent concurrent modifications
4. **Separate state by environment** (dev, staging, prod)
5. **Use least privilege** IAM policies for state access
6. **Never commit state** to version control
7. **Back up state** regularly
8. **Use partial configuration** to avoid hardcoding secrets

## Lab Exercise

1. Create S3 bucket and DynamoDB table for state storage
2. Configure S3 backend with state locking
3. Migrate existing local state to remote backend
4. Test state locking with concurrent applies
5. Access remote state outputs from another configuration
