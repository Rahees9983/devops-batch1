# Terraform Resource Attributes

## What are Resource Attributes?

Resource attributes are the properties of infrastructure resources that Terraform manages. There are two types:

1. **Arguments**: Values you set to configure the resource
2. **Attributes**: Values that are computed/returned by the provider after resource creation

## Arguments vs Attributes

### Arguments (Input)

```hcl
resource "aws_instance" "example" {
  # These are ARGUMENTS - you specify them
  ami           = "ami-0c55b159cbfafe1f0"  # argument
  instance_type = "t2.micro"                 # argument

  tags = {                                   # argument
    Name = "my-instance"
  }
}
```

### Attributes (Output)

```hcl
# These are ATTRIBUTES - computed after creation
# You reference them, not set them

# aws_instance.example.id          - Instance ID (computed)
# aws_instance.example.public_ip   - Public IP (computed)
# aws_instance.example.private_ip  - Private IP (computed)
# aws_instance.example.arn         - ARN (computed)
```

## Referencing Resource Attributes

### Basic Reference Syntax

```
resource_type.resource_name.attribute_name
```

### Examples

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id          # Reference VPC's id attribute
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id   # Reference subnet's id attribute
}

output "instance_ip" {
  value = aws_instance.web.public_ip     # Reference instance's public_ip attribute
}
```

## Common Resource Attributes by Provider

### AWS EC2 Instance

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# Available attributes after creation:
# aws_instance.example.id                    - Instance ID
# aws_instance.example.arn                   - Instance ARN
# aws_instance.example.public_ip             - Public IP address
# aws_instance.example.private_ip            - Private IP address
# aws_instance.example.public_dns            - Public DNS name
# aws_instance.example.private_dns           - Private DNS name
# aws_instance.example.availability_zone     - Availability zone
# aws_instance.example.security_groups       - Security groups
# aws_instance.example.subnet_id             - Subnet ID
# aws_instance.example.primary_network_interface_id - Primary ENI ID
```

### AWS S3 Bucket

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket"
}

# Available attributes:
# aws_s3_bucket.example.id                   - Bucket name (same as bucket)
# aws_s3_bucket.example.arn                  - Bucket ARN
# aws_s3_bucket.example.bucket_domain_name   - Bucket domain name
# aws_s3_bucket.example.bucket_regional_domain_name
# aws_s3_bucket.example.hosted_zone_id       - Route 53 hosted zone ID
# aws_s3_bucket.example.region               - AWS region
```

### AWS VPC

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Available attributes:
# aws_vpc.main.id                            - VPC ID
# aws_vpc.main.arn                           - VPC ARN
# aws_vpc.main.cidr_block                    - CIDR block
# aws_vpc.main.default_network_acl_id        - Default NACL ID
# aws_vpc.main.default_route_table_id        - Default route table ID
# aws_vpc.main.default_security_group_id     - Default security group ID
# aws_vpc.main.main_route_table_id           - Main route table ID
# aws_vpc.main.owner_id                      - AWS account ID
```

### AWS Security Group

```hcl
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Available attributes:
# aws_security_group.web.id                  - Security group ID
# aws_security_group.web.arn                 - Security group ARN
# aws_security_group.web.owner_id            - AWS account ID
# aws_security_group.web.name                - Security group name
# aws_security_group.web.vpc_id              - VPC ID
```

## Attribute Dependencies (Implicit)

When you reference an attribute, Terraform creates an implicit dependency:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# This resource depends on aws_vpc.main
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id    # Implicit dependency created here
  cidr_block = "10.0.1.0/24"
}

# This resource depends on aws_subnet.public (and transitively on aws_vpc.main)
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id  # Implicit dependency
}
```

## Attributes with count and for_each

### With count

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# Reference specific instance
output "first_instance_ip" {
  value = aws_instance.web[0].public_ip
}

# Reference all instances (splat expression)
output "all_instance_ips" {
  value = aws_instance.web[*].public_ip
}

# Reference all IDs
output "all_instance_ids" {
  value = aws_instance.web[*].id
}
```

### With for_each

```hcl
resource "aws_instance" "servers" {
  for_each = {
    web = "t2.micro"
    app = "t2.small"
    db  = "t2.medium"
  }

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value

  tags = {
    Name = each.key
  }
}

# Reference specific instance
output "web_server_ip" {
  value = aws_instance.servers["web"].public_ip
}

# Reference all instances
output "all_server_ips" {
  value = {
    for name, instance in aws_instance.servers :
    name => instance.public_ip
  }
}
```

## Self Reference

Use `self` to reference the current resource's attributes:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}
```

## Nested Attributes

Some attributes are nested within blocks:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

# Access nested attribute
output "root_volume_id" {
  value = aws_instance.web.root_block_device[0].volume_id
}
```

## Complete Example

```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Using VPC's id attribute
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "web-server"
  }
}

# outputs.tf - Using various resource attributes
output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "security_group_id" {
  value = aws_security_group.web.id
}

output "instance_id" {
  value = aws_instance.web.id
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
}

output "ssh_command" {
  value = "ssh -i key.pem ec2-user@${aws_instance.web.public_ip}"
}
```

## Finding Available Attributes

To find what attributes a resource exports:

1. **Terraform Registry Documentation**: Visit registry.terraform.io and look up the resource
2. **terraform show**: After apply, shows all attributes
3. **terraform state show**: Shows attributes of a specific resource

```bash
# Show all state
terraform show

# Show specific resource
terraform state show aws_instance.web
```

## Best Practices

1. **Use attributes for dependencies** instead of hardcoding values
2. **Reference computed attributes** in outputs for visibility
3. **Use splat expressions** for resources with count
4. **Use for expressions** for resources with for_each
5. **Check documentation** for all available attributes
