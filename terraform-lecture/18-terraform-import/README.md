# Terraform Import

## What is Terraform Import?

Terraform Import brings existing infrastructure under Terraform management. It allows you to:

- Adopt manually created resources
- Migrate from other IaC tools
- Take over unmanaged infrastructure
- Recover from state loss

## Import Methods

1. **terraform import command** - Traditional method (import one resource at a time)
2. **import block** - Declarative import (Terraform 1.5+)

---

## terraform import Command

### Basic Syntax

```bash
terraform import <resource_address> <resource_id>
```

### Prerequisites

1. Write the resource configuration in your .tf files
2. The resource must not already exist in state
3. You need the resource's ID from your cloud provider

### Example: Import EC2 Instance

```hcl
# 1. First, write the resource configuration
# main.tf
resource "aws_instance" "imported" {
  # Configuration will be populated after import
  # For now, add minimal required attributes
  ami           = "ami-0c55b159cbfafe1f0"  # Placeholder
  instance_type = "t2.micro"               # Placeholder
}
```

```bash
# 2. Run import command
terraform import aws_instance.imported i-0abc123def456789

# Output:
# aws_instance.imported: Importing from ID "i-0abc123def456789"...
# aws_instance.imported: Import prepared!
# aws_instance.imported: Refreshing state...
#
# Import successful!
```

```bash
# 3. Show the imported state
terraform state show aws_instance.imported

# 4. Update your configuration to match the state
# Copy attributes from state show output to your .tf file
```

---

## Common Import Examples

### AWS VPC

```bash
terraform import aws_vpc.main vpc-abc123
```

### AWS Subnet

```bash
terraform import aws_subnet.public subnet-abc123
```

### AWS Security Group

```bash
terraform import aws_security_group.web sg-abc123
```

### AWS S3 Bucket

```bash
terraform import aws_s3_bucket.data my-bucket-name
```

### AWS RDS Instance

```bash
terraform import aws_db_instance.main mydb-instance-identifier
```

### AWS IAM Role

```bash
terraform import aws_iam_role.app my-role-name
```

### AWS IAM Policy

```bash
terraform import aws_iam_policy.custom arn:aws:iam::123456789:policy/MyPolicy
```

### AWS Route53 Zone

```bash
terraform import aws_route53_zone.main Z1234567890ABC
```

### AWS EKS Cluster

```bash
terraform import aws_eks_cluster.main my-cluster-name
```

### Azure Resource Group

```bash
terraform import azurerm_resource_group.main /subscriptions/xxx/resourceGroups/my-rg
```

### GCP Compute Instance

```bash
terraform import google_compute_instance.main projects/my-project/zones/us-central1-a/instances/my-instance
```

---

## Import Block (Terraform 1.5+)

Declarative import using configuration blocks.

### Basic Syntax

```hcl
import {
  id = "resource-id"
  to = resource_type.resource_name
}
```

### Example: Import with Block

```hcl
# imports.tf
import {
  id = "i-0abc123def456789"
  to = aws_instance.web
}

import {
  id = "vpc-abc123"
  to = aws_vpc.main
}

import {
  id = "sg-abc123"
  to = aws_security_group.web
}

# main.tf
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # Other attributes...
}

resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id
  # Other attributes...
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  # Other attributes...
}
```

```bash
# Run plan to see what will be imported
terraform plan

# Apply to perform the import
terraform apply
```

### Dynamic Import IDs

```hcl
variable "instance_ids" {
  type = list(string)
  default = ["i-abc123", "i-def456", "i-ghi789"]
}

import {
  for_each = toset(var.instance_ids)
  id       = each.value
  to       = aws_instance.servers[each.value]
}

resource "aws_instance" "servers" {
  for_each      = toset(var.instance_ids)
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

---

## Generating Configuration

### Using -generate-config-out (Terraform 1.5+)

Automatically generate configuration for imported resources.

```hcl
# imports.tf
import {
  id = "i-0abc123def456789"
  to = aws_instance.imported
}
```

```bash
# Generate configuration
terraform plan -generate-config-out=generated.tf

# Review and edit generated.tf
cat generated.tf
```

### Generated Configuration Example

```hcl
# generated.tf (auto-generated)
resource "aws_instance" "imported" {
  ami                         = "ami-0c55b159cbfafe1f0"
  associate_public_ip_address = true
  availability_zone           = "us-east-1a"
  instance_type               = "t2.micro"
  key_name                    = "my-key"
  subnet_id                   = "subnet-abc123"
  vpc_security_group_ids      = ["sg-abc123"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 8
    volume_type           = "gp2"
  }

  tags = {
    Name = "my-instance"
  }
}
```

---

## Import Workflow

### Step-by-Step Process

```
1. Identify existing resources to import
         ↓
2. Get resource IDs from cloud console/CLI
         ↓
3. Write resource blocks in .tf files (or use -generate-config-out)
         ↓
4. Run terraform import (or terraform apply with import blocks)
         ↓
5. Run terraform plan to verify no changes
         ↓
6. Adjust configuration until plan shows no changes
         ↓
7. Remove import blocks (if used)
```

### Verification

```bash
# After import, plan should show no changes
terraform plan

# Output should be:
# No changes. Your infrastructure matches the configuration.
```

---

## Import Complex Resources

### Import Resources with count

```bash
# Import to specific index
terraform import 'aws_instance.web[0]' i-abc123
terraform import 'aws_instance.web[1]' i-def456
terraform import 'aws_instance.web[2]' i-ghi789
```

### Import Resources with for_each

```bash
# Import to specific key
terraform import 'aws_instance.servers["web"]' i-abc123
terraform import 'aws_instance.servers["app"]' i-def456
terraform import 'aws_instance.servers["db"]' i-ghi789
```

### Import into Modules

```bash
# Import resource inside a module
terraform import 'module.vpc.aws_vpc.main' vpc-abc123
terraform import 'module.vpc.aws_subnet.public[0]' subnet-abc123
```

---

## Practical Examples

### Example 1: Import Existing VPC Infrastructure

```hcl
# imports.tf
import {
  id = "vpc-abc123"
  to = aws_vpc.main
}

import {
  id = "igw-abc123"
  to = aws_internet_gateway.main
}

import {
  id = "subnet-pub1"
  to = aws_subnet.public[0]
}

import {
  id = "subnet-pub2"
  to = aws_subnet.public[1]
}

import {
  id = "rtb-abc123"
  to = aws_route_table.public
}
```

```bash
# Generate configuration
terraform plan -generate-config-out=vpc_generated.tf

# Review and apply
terraform apply
```

### Example 2: Import S3 Bucket with Configuration

```hcl
import {
  id = "my-existing-bucket"
  to = aws_s3_bucket.data
}

import {
  id = "my-existing-bucket"
  to = aws_s3_bucket_versioning.data
}

import {
  id = "my-existing-bucket"
  to = aws_s3_bucket_server_side_encryption_configuration.data
}

resource "aws_s3_bucket" "data" {
  bucket = "my-existing-bucket"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### Example 3: Batch Import Script

```bash
#!/bin/bash
# import-infrastructure.sh

# Import VPC resources
terraform import aws_vpc.main vpc-abc123
terraform import aws_internet_gateway.main igw-abc123
terraform import aws_subnet.public subnet-pub123
terraform import aws_subnet.private subnet-priv123
terraform import aws_route_table.public rtb-pub123
terraform import aws_route_table.private rtb-priv123

# Import security groups
terraform import aws_security_group.web sg-web123
terraform import aws_security_group.db sg-db123

# Import instances
terraform import aws_instance.web i-web123
terraform import aws_instance.db i-db123

# Verify
terraform plan
```

---

## Import Limitations

### What Can't Be Imported

1. **Resources without import support**: Check provider documentation
2. **Certain resource attributes**: Some attributes can't be read back
3. **Passwords/secrets**: Often not returned by APIs

### Post-Import Adjustments

Some attributes may need manual adjustment:

```hcl
resource "aws_db_instance" "main" {
  identifier = "mydb"
  # Password can't be imported - must be set
  password = var.db_password

  # These might not import correctly
  lifecycle {
    ignore_changes = [password]
  }
}
```

---

## Best Practices

1. **Back up existing state** before importing
   ```bash
   terraform state pull > backup.tfstate
   ```

2. **Import in small batches** - Don't import everything at once

3. **Verify with plan** - Always run plan after import

4. **Use generate-config-out** - Let Terraform generate initial config

5. **Document imports** - Track what was imported and when

6. **Test in non-prod first** - Practice import process

7. **Remove import blocks** after successful import

8. **Handle sensitive data** - Import blocks may reference IDs

---

## Troubleshooting

### Error: Resource already managed

```
Error: Resource already managed by Terraform
```

**Solution:** Resource exists in state. Remove it first:
```bash
terraform state rm aws_instance.web
terraform import aws_instance.web i-abc123
```

### Error: Configuration doesn't match

```
Error: planned change after import
```

**Solution:** Adjust your configuration to match the imported resource:
```bash
terraform state show aws_instance.web
# Update your .tf file to match
```

### Error: Import not supported

```
Error: resource does not support import
```

**Solution:** Check provider documentation. Some resources can't be imported.

---

## Lab Exercise

1. Create an EC2 instance manually in AWS Console
2. Write a resource block for it in Terraform
3. Import the instance using `terraform import`
4. Verify with `terraform plan` (should show no changes)
5. Try the import block method with a new resource
6. Use `-generate-config-out` to auto-generate configuration
