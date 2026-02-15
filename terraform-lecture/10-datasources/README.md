# Terraform Data Sources

## What are Data Sources?

Data sources allow Terraform to fetch information from external sources or existing infrastructure. They provide read-only access to data defined outside of Terraform.

## Data Source vs Resource

| Aspect | Resource | Data Source |
|--------|----------|-------------|
| Purpose | Create/manage infrastructure | Query existing infrastructure |
| Keyword | `resource` | `data` |
| State | Tracked in state | Refreshed on every plan |
| Lifecycle | Create, update, destroy | Read-only |

## Basic Syntax

```hcl
data "provider_type" "name" {
  # Query parameters
  filter = "value"
}

# Reference
data.provider_type.name.attribute
```

## Common AWS Data Sources

### aws_ami - Find AMI Images

```hcl
# Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
}

# Output AMI details
output "ami_id" {
  value = data.aws_ami.amazon_linux.id
}

output "ami_name" {
  value = data.aws_ami.amazon_linux.name
}
```

### aws_availability_zones - Get AZs

```hcl
# Get all available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Use AZs for subnet creation
resource "aws_subnet" "public" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

output "available_azs" {
  value = data.aws_availability_zones.available.names
}
```

### aws_vpc - Query Existing VPC

```hcl
# Find VPC by tag
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["production-vpc"]
  }
}

# Find default VPC
data "aws_vpc" "default" {
  default = true
}

# Use the VPC ID
resource "aws_subnet" "new" {
  vpc_id     = data.aws_vpc.existing.id
  cidr_block = "10.0.100.0/24"
}

output "vpc_cidr" {
  value = data.aws_vpc.existing.cidr_block
}
```

### aws_subnet - Query Existing Subnet

```hcl
# Find subnet by ID
data "aws_subnet" "selected" {
  id = "subnet-abc123"
}

# Find subnets by filter
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# Use in resources
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.private.ids[0]
}
```

### aws_caller_identity - Get Current AWS Account

```hcl
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

# Use in IAM policies
resource "aws_iam_policy" "example" {
  name = "example-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = "arn:aws:s3:::bucket-${data.aws_caller_identity.current.account_id}/*"
    }]
  })
}
```

### aws_region - Get Current Region

```hcl
data "aws_region" "current" {}

output "region_name" {
  value = data.aws_region.current.name
}

output "region_description" {
  value = data.aws_region.current.description
}
```

### aws_iam_policy_document - Build IAM Policies

```hcl
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "AllowS3Read"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
  }

  statement {
    sid    = "AllowS3Write"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.example.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["private"]
    }
  }
}

resource "aws_iam_role" "example" {
  name               = "example-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "example" {
  name   = "example-policy"
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.s3_access.json
}
```

### aws_secretsmanager_secret - Get Secrets

```hcl
data "aws_secretsmanager_secret" "db_creds" {
  name = "production/database/credentials"
}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.aws_secretsmanager_secret.db_creds.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

resource "aws_db_instance" "main" {
  identifier        = "production-db"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = local.db_creds.username
  password          = local.db_creds.password
}
```

### aws_ssm_parameter - Get SSM Parameters

```hcl
data "aws_ssm_parameter" "db_password" {
  name            = "/production/database/password"
  with_decryption = true
}

data "aws_ssm_parameters_by_path" "app_config" {
  path            = "/production/app/"
  with_decryption = true
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              export DB_PASSWORD="${data.aws_ssm_parameter.db_password.value}"
              /opt/app/start.sh
              EOF
}
```

## External Data Sources

### external - Run External Scripts

```hcl
data "external" "example" {
  program = ["python3", "${path.module}/scripts/get_data.py"]

  query = {
    environment = var.environment
    region      = var.region
  }
}

# scripts/get_data.py
# import json
# import sys
#
# input_data = json.load(sys.stdin)
# result = {
#     "value": f"processed-{input_data['environment']}"
# }
# print(json.dumps(result))

output "external_value" {
  value = data.external.example.result.value
}
```

### http - Fetch HTTP Data

```hcl
data "http" "myip" {
  url = "https://api.ipify.org?format=json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  my_ip = jsondecode(data.http.myip.response_body).ip
}

resource "aws_security_group_rule" "allow_my_ip" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${local.my_ip}/32"]
  security_group_id = aws_security_group.example.id
}
```

### local_file - Read Local Files

```hcl
data "local_file" "public_key" {
  filename = "${path.module}/keys/id_rsa.pub"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = data.local_file.public_key.content
}
```

### template_file - Template Rendering (Deprecated, use templatefile function)

```hcl
# Modern approach using templatefile function
locals {
  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    db_host     = aws_db_instance.main.address
    db_name     = var.db_name
    environment = var.environment
  })
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  user_data     = local.user_data
}
```

## Kubernetes Data Sources

```hcl
data "kubernetes_namespace" "existing" {
  metadata {
    name = "default"
  }
}

data "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = "production"
  }
}

data "kubernetes_secret" "db_creds" {
  metadata {
    name      = "database-credentials"
    namespace = "production"
  }
}

# Use the data
locals {
  db_host     = data.kubernetes_config_map.app_config.data["DB_HOST"]
  db_password = base64decode(data.kubernetes_secret.db_creds.data["password"])
}
```

## Combining Data Sources

```hcl
# Complete example using multiple data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Use all data sources
resource "aws_iam_role" "app" {
  name               = "app-role-${data.aws_caller_identity.current.account_id}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_instance" "app" {
  count         = min(length(data.aws_availability_zones.available.names), 2)
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.default.ids[count.index]

  tags = {
    Name   = "app-${count.index + 1}"
    Region = data.aws_region.current.name
  }
}

output "deployment_info" {
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    vpc_id     = data.aws_vpc.default.id
    ami_id     = data.aws_ami.amazon_linux.id
  }
}
```

## Best Practices

1. **Use data sources** to reference existing infrastructure instead of hardcoding IDs
2. **Filter carefully** to ensure you get the expected resource
3. **Use `most_recent = true`** when querying AMIs
4. **Handle missing data** gracefully with conditionals
5. **Cache expensive lookups** in locals when used multiple times
6. **Document dependencies** on external resources

## Lab Exercise

1. Create a data source to find the latest Ubuntu AMI
2. Query the default VPC and its subnets
3. Use aws_caller_identity to tag resources with account ID
4. Create an EC2 instance using all the queried data
