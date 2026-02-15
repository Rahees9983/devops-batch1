# Terraform Conditional Expressions

## Overview

Conditional expressions allow you to choose between values based on a condition. They're essential for creating flexible, reusable configurations.

## Basic Syntax

```hcl
condition ? true_value : false_value
```

If `condition` is true, the result is `true_value`. Otherwise, it's `false_value`.

---

## Simple Conditionals

### Basic Example

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

# Select instance type based on environment
locals {
  instance_type = var.environment == "prod" ? "t2.large" : "t2.micro"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = local.instance_type
}
```

### Boolean Variables

```hcl
variable "enable_monitoring" {
  type    = bool
  default = false
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  monitoring    = var.enable_monitoring ? true : false
  # Simplified: monitoring = var.enable_monitoring
}
```

---

## Conditional Resource Creation

### Using count

```hcl
variable "create_instance" {
  type    = bool
  default = true
}

resource "aws_instance" "web" {
  count         = var.create_instance ? 1 : 0
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

### Environment-Based Creation

```hcl
variable "environment" {
  type = string
}

# Only create NAT Gateway in production
resource "aws_nat_gateway" "main" {
  count         = var.environment == "prod" ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
}

resource "aws_eip" "nat" {
  count  = var.environment == "prod" ? 1 : 0
  domain = "vpc"
}
```

### Multiple Conditions

```hcl
# Create bastion host only in dev and staging
resource "aws_instance" "bastion" {
  count         = var.environment != "prod" ? 1 : 0
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "bastion-${var.environment}"
  }
}
```

---

## Conditional Attribute Values

### Select Between Values

```hcl
variable "environment" {
  type = string
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.environment == "prod" ? "t2.large" : "t2.micro"

  root_block_device {
    volume_size = var.environment == "prod" ? 100 : 20
    volume_type = var.environment == "prod" ? "gp3" : "gp2"
  }

  tags = {
    Name        = "web-${var.environment}"
    Environment = var.environment
  }
}
```

### Conditional Tags

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = var.environment == "prod" ? {
    Name        = "production-web"
    Environment = "production"
    Critical    = "true"
  } : {
    Name        = "development-web"
    Environment = "development"
  }
}
```

### Conditional Merge

```hcl
locals {
  base_tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }

  prod_tags = {
    Critical    = "true"
    BackupDaily = "true"
  }

  all_tags = var.environment == "prod" ? merge(local.base_tags, local.prod_tags) : local.base_tags
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags          = local.all_tags
}
```

---

## Nested Conditionals

### Chained Conditions

```hcl
variable "environment" {
  type = string
}

locals {
  # Nested ternary for multiple environments
  instance_type = (
    var.environment == "prod" ? "t2.large" :
    var.environment == "staging" ? "t2.medium" :
    "t2.micro"  # default for dev
  )
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = local.instance_type
}
```

### Using lookup (Alternative)

```hcl
locals {
  instance_types = {
    dev     = "t2.micro"
    staging = "t2.medium"
    prod    = "t2.large"
  }

  # More readable than nested ternary
  instance_type = lookup(local.instance_types, var.environment, "t2.micro")
}
```

---

## Conditional Outputs

```hcl
variable "create_load_balancer" {
  type    = bool
  default = true
}

resource "aws_lb" "main" {
  count              = var.create_load_balancer ? 1 : 0
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = var.create_load_balancer ? aws_lb.main[0].dns_name : null
}

# Alternative using try
output "load_balancer_dns_alt" {
  value = try(aws_lb.main[0].dns_name, "No load balancer created")
}
```

---

## Conditional Dynamic Blocks

```hcl
variable "enable_ingress_rules" {
  type    = bool
  default = true
}

variable "ingress_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    { port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.enable_ingress_rules ? var.ingress_rules : []
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## Conditional with for_each

```hcl
variable "create_dns_records" {
  type    = bool
  default = true
}

variable "dns_records" {
  type = map(object({
    type  = string
    value = string
  }))
  default = {
    www = { type = "A", value = "10.0.1.5" }
    api = { type = "A", value = "10.0.1.6" }
  }
}

resource "aws_route53_record" "records" {
  for_each = var.create_dns_records ? var.dns_records : {}

  zone_id = aws_route53_zone.main.zone_id
  name    = each.key
  type    = each.value.type
  ttl     = 300
  records = [each.value.value]
}
```

---

## Conditional Lists

### Building Lists Conditionally

```hcl
variable "environment" {
  type = string
}

variable "enable_https" {
  type    = bool
  default = true
}

locals {
  # Build security group rules list conditionally
  ingress_ports = concat(
    [22, 80],  # Always include SSH and HTTP
    var.enable_https ? [443] : [],  # Conditionally add HTTPS
    var.environment == "dev" ? [8080] : []  # Dev-only debug port
  )
}

resource "aws_security_group_rule" "ingress" {
  count             = length(local.ingress_ports)
  type              = "ingress"
  from_port         = local.ingress_ports[count.index]
  to_port           = local.ingress_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}
```

### Conditional List Elements

```hcl
locals {
  subnets = [
    for i, az in var.availability_zones : {
      name   = "subnet-${i}"
      az     = az
      public = i < 2  # First two are public
    }
  ]

  public_subnets  = [for s in local.subnets : s if s.public]
  private_subnets = [for s in local.subnets : s if !s.public]
}
```

---

## Conditional Maps

```hcl
variable "environment" {
  type = string
}

locals {
  # Base configuration for all environments
  base_config = {
    instance_type = "t2.micro"
    monitoring    = false
    backup        = false
  }

  # Production overrides
  prod_config = {
    instance_type = "t2.large"
    monitoring    = true
    backup        = true
  }

  # Merge configurations based on environment
  config = var.environment == "prod" ? merge(local.base_config, local.prod_config) : local.base_config
}
```

---

## Practical Examples

### Example 1: Multi-Environment Database

```hcl
variable "environment" {
  type = string
}

locals {
  db_config = {
    dev = {
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      multi_az          = false
      backup_retention  = 0
    }
    staging = {
      instance_class    = "db.t3.small"
      allocated_storage = 50
      multi_az          = false
      backup_retention  = 7
    }
    prod = {
      instance_class    = "db.t3.medium"
      allocated_storage = 100
      multi_az          = true
      backup_retention  = 30
    }
  }

  current_config = local.db_config[var.environment]
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project}-${var.environment}"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = local.current_config.instance_class
  allocated_storage = local.current_config.allocated_storage
  multi_az          = local.current_config.multi_az
  backup_retention_period = local.current_config.backup_retention

  # Skip final snapshot in non-prod
  skip_final_snapshot = var.environment != "prod"

  # Delete protection only in prod
  deletion_protection = var.environment == "prod"
}
```

### Example 2: Conditional VPC Setup

```hcl
variable "create_nat_gateway" {
  description = "Whether to create NAT Gateway (expensive)"
  type        = bool
  default     = false
}

variable "use_single_nat" {
  description = "Use single NAT for all AZs (cost saving)"
  type        = bool
  default     = true
}

locals {
  nat_gateway_count = var.create_nat_gateway ? (var.use_single_nat ? 1 : length(var.availability_zones)) : 0
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-${count.index + 1}"
  }
}
```

### Example 3: Feature Flags

```hcl
variable "features" {
  type = object({
    enable_cdn         = bool
    enable_waf         = bool
    enable_monitoring  = bool
    enable_logging     = bool
  })
  default = {
    enable_cdn         = false
    enable_waf         = false
    enable_monitoring  = true
    enable_logging     = true
  }
}

# CloudFront CDN
resource "aws_cloudfront_distribution" "main" {
  count = var.features.enable_cdn ? 1 : 0
  # ... configuration
}

# WAF
resource "aws_wafv2_web_acl" "main" {
  count = var.features.enable_waf ? 1 : 0
  # ... configuration
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.features.enable_monitoring ? 1 : 0
  # ... configuration
}

# S3 Access Logging
resource "aws_s3_bucket" "logs" {
  count  = var.features.enable_logging ? 1 : 0
  bucket = "${var.project}-logs"
}
```

---

## Best Practices

1. **Keep conditions simple** - Complex nested ternaries are hard to read
2. **Use lookup for multiple values** - Prefer lookup over nested ternaries
3. **Use locals for complex logic** - Calculate conditions in locals for clarity
4. **Default to safe values** - The false case should be the safe/minimal option
5. **Document conditional resources** - Add comments explaining when resources are created
6. **Test all paths** - Ensure both true and false cases work

---

## Common Patterns

### Pattern: Optional Resource

```hcl
variable "create_resource" {
  type    = bool
  default = false
}

resource "aws_resource" "optional" {
  count = var.create_resource ? 1 : 0
  # ...
}

output "resource_id" {
  value = var.create_resource ? aws_resource.optional[0].id : null
}
```

### Pattern: Environment Switch

```hcl
locals {
  is_prod    = var.environment == "prod"
  is_staging = var.environment == "staging"
  is_dev     = var.environment == "dev"
}

resource "aws_instance" "web" {
  instance_type = local.is_prod ? "t2.large" : "t2.micro"
  monitoring    = local.is_prod || local.is_staging
}
```

### Pattern: Coalesce Fallback

```hcl
variable "custom_name" {
  type    = string
  default = ""
}

locals {
  name = var.custom_name != "" ? var.custom_name : "${var.project}-${var.environment}"
  # Or using coalesce:
  name_alt = coalesce(var.custom_name, "${var.project}-${var.environment}")
}
```

---

## Lab Exercise

1. Create a conditional EC2 instance (only in dev)
2. Use ternary to select instance type based on environment
3. Create conditional security group rules
4. Implement feature flags for optional resources
5. Build a multi-environment configuration using conditionals
