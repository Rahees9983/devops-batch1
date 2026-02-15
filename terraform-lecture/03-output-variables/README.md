# Terraform Output Variables

## What are Output Variables?

Output variables expose information about your infrastructure on the command line and can share data between Terraform modules. They are useful for:

- Displaying important resource attributes after apply
- Passing data between modules
- Providing information for external scripts or automation

## Basic Syntax

```hcl
output "output_name" {
  description = "Description of the output"
  value       = resource_type.resource_name.attribute
}
```

## Simple Output Examples

```hcl
# main.tf
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server"
  }
}

# outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}
```

## Output Attributes

### description

```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}
```

### sensitive

```hcl
output "db_password" {
  description = "Database password"
  value       = random_password.db.result
  sensitive   = true
}

output "api_key" {
  description = "API key for the application"
  value       = aws_api_gateway_api_key.example.value
  sensitive   = true
}
```

### depends_on

```hcl
output "application_url" {
  description = "URL of the application"
  value       = "http://${aws_instance.web.public_dns}"
  depends_on  = [aws_security_group_rule.allow_http]
}
```

## Complex Output Types

### List Output

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

output "instance_ids" {
  description = "IDs of all EC2 instances"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Public IPs of all EC2 instances"
  value       = aws_instance.web[*].public_ip
}
```

### Map Output

```hcl
resource "aws_instance" "servers" {
  for_each      = toset(["web", "app", "db"])
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = each.key
  }
}

output "server_ips" {
  description = "Map of server names to their private IPs"
  value = {
    for name, instance in aws_instance.servers :
    name => instance.private_ip
  }
}

output "server_details" {
  description = "Detailed information about each server"
  value = {
    for name, instance in aws_instance.servers :
    name => {
      id         = instance.id
      private_ip = instance.private_ip
      public_ip  = instance.public_ip
    }
  }
}
```

### Object Output

```hcl
output "vpc_info" {
  description = "VPC information"
  value = {
    id         = aws_vpc.main.id
    cidr_block = aws_vpc.main.cidr_block
    arn        = aws_vpc.main.arn
  }
}
```

## Accessing Outputs

### Command Line

```bash
# View all outputs
terraform output

# View specific output
terraform output instance_public_ip

# Get raw value (without quotes)
terraform output -raw instance_public_ip

# Get output as JSON
terraform output -json

# Get specific output as JSON
terraform output -json instance_public_ips
```

### In Scripts

```bash
# Use in shell scripts
INSTANCE_IP=$(terraform output -raw instance_public_ip)
ssh ec2-user@$INSTANCE_IP

# Use with jq for JSON parsing
terraform output -json server_ips | jq '.web'
```

## Outputs in Modules

### Child Module (modules/webserver/outputs.tf)

```hcl
output "instance_id" {
  description = "ID of the web server instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}
```

### Root Module (main.tf)

```hcl
module "webserver" {
  source        = "./modules/webserver"
  instance_type = "t2.micro"
  vpc_id        = aws_vpc.main.id
}

# Access module outputs
output "webserver_ip" {
  description = "Public IP of the web server"
  value       = module.webserver.public_ip
}

# Use module output in another resource
resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "web.example.com"
  type    = "A"
  ttl     = 300
  records = [module.webserver.public_ip]
}
```

## Conditional Outputs

```hcl
output "load_balancer_dns" {
  description = "DNS name of the load balancer (if created)"
  value       = var.create_lb ? aws_lb.main[0].dns_name : null
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = var.environment == "prod" ? aws_db_instance.prod[0].endpoint : aws_db_instance.dev[0].endpoint
}
```

## Output Formatting with Functions

```hcl
output "connection_string" {
  description = "Database connection string"
  value       = "postgresql://${var.db_user}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
  sensitive   = true
}

output "instance_info" {
  description = "Formatted instance information"
  value       = format("Instance %s is running at %s", aws_instance.web.id, aws_instance.web.public_ip)
}

output "all_subnet_ids" {
  description = "Comma-separated list of subnet IDs"
  value       = join(",", aws_subnet.private[*].id)
}
```

## Complete Example

```hcl
# main.tf
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
  }
}

resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id

  tags = {
    Name = "${var.environment}-web-${count.index + 1}"
  }
}

resource "random_password" "db" {
  length  = 16
  special = true
}

# outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = aws_instance.web[*].public_ip
}

output "instance_details" {
  description = "Detailed information about instances"
  value = [
    for i, instance in aws_instance.web : {
      name       = "${var.environment}-web-${i + 1}"
      id         = instance.id
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  ]
}

output "db_password" {
  description = "Generated database password"
  value       = random_password.db.result
  sensitive   = true
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for ip in aws_instance.web[*].public_ip :
    "ssh -i key.pem ec2-user@${ip}"
  ]
}
```

## Best Practices

1. **Always add descriptions** to outputs for documentation
2. **Mark sensitive outputs** appropriately
3. **Use meaningful names** that describe the value
4. **Group related outputs** together
5. **Use outputs for module interfaces** to expose necessary data

## Lab Exercise

Create outputs that:
1. Display all EC2 instance IDs and IPs
2. Show a formatted connection string
3. Create a map of instance names to their IPs
4. Include a sensitive output for credentials
