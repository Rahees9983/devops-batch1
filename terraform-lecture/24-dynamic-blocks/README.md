# Terraform Dynamic Blocks

## What are Dynamic Blocks?

Dynamic blocks allow you to dynamically construct repeatable nested blocks within resources, data sources, providers, and provisioners. They are useful when you need to create multiple similar nested blocks based on a variable or local value.

## When to Use Dynamic Blocks

- When the number of nested blocks is not known until runtime
- When nested block configuration comes from a variable or data source
- When you want to avoid code repetition for similar blocks
- When block configuration needs to be conditional

## Basic Syntax

```hcl
dynamic "block_name" {
  for_each = collection

  content {
    # Block content using dynamic.value
    attribute = block_name.value.attribute_name
  }
}
```

## Key Components

| Component | Description |
|-----------|-------------|
| `dynamic` | Keyword to start a dynamic block |
| `"block_name"` | Name of the nested block to generate (e.g., "ingress", "tag") |
| `for_each` | Collection to iterate over (list, set, or map) |
| `content` | The actual content of each generated block |
| `block_name.value` | Current element in iteration |
| `block_name.key` | Current key (index for lists, key for maps) |

## Iterator Variable

By default, the iterator variable name matches the block name. You can customize it:

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  iterator = rule  # Custom iterator name

  content {
    from_port   = rule.value.port
    to_port     = rule.value.port
    protocol    = rule.value.protocol
    cidr_blocks = rule.value.cidrs
  }
}
```

## Common Use Cases

### 1. Security Group Rules

```hcl
variable "ingress_rules" {
  default = [
    { port = 22,  protocol = "tcp", cidrs = ["10.0.0.0/8"], description = "SSH" },
    { port = 80,  protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTP" },
    { port = 443, protocol = "tcp", cidrs = ["0.0.0.0/0"], description = "HTTPS" },
  ]
}

resource "aws_security_group" "example" {
  name   = "dynamic-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidrs
      description = ingress.value.description
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

### 2. EBS Volumes

```hcl
variable "ebs_volumes" {
  default = [
    { device = "/dev/sdb", size = 100, type = "gp3" },
    { device = "/dev/sdc", size = 200, type = "gp3" },
  ]
}

resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t3.large"

  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes

    content {
      device_name           = ebs_block_device.value.device
      volume_size           = ebs_block_device.value.size
      volume_type           = ebs_block_device.value.type
      delete_on_termination = true
      encrypted             = true
    }
  }
}
```

### 3. Tags

```hcl
variable "tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "demo"
    Owner       = "devops"
  }
}

resource "aws_autoscaling_group" "example" {
  # ... other configuration ...

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
```

### 4. IAM Policy Statements

```hcl
variable "policy_statements" {
  default = [
    {
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::my-bucket/*"]
    },
    {
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup", "logs:PutLogEvents"]
      resources = ["*"]
    }
  ]
}

data "aws_iam_policy_document" "example" {
  dynamic "statement" {
    for_each = var.policy_statements

    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}
```

## Nested Dynamic Blocks

You can nest dynamic blocks for complex structures:

```hcl
variable "load_balancer_config" {
  default = {
    listeners = [
      {
        port     = 80
        protocol = "HTTP"
        actions = [
          { type = "redirect", redirect_port = 443 }
        ]
      },
      {
        port     = 443
        protocol = "HTTPS"
        actions = [
          { type = "forward", target_group = "main" }
        ]
      }
    ]
  }
}

resource "aws_lb_listener" "example" {
  for_each = { for l in var.load_balancer_config.listeners : l.port => l }

  load_balancer_arn = aws_lb.main.arn
  port              = each.value.port
  protocol          = each.value.protocol

  dynamic "default_action" {
    for_each = each.value.actions

    content {
      type = default_action.value.type

      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" ? [1] : []

        content {
          port        = default_action.value.redirect_port
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }

      dynamic "forward" {
        for_each = default_action.value.type == "forward" ? [1] : []

        content {
          target_group {
            arn = aws_lb_target_group.main.arn
          }
        }
      }
    }
  }
}
```

## Conditional Dynamic Blocks

Create blocks conditionally using empty collections:

```hcl
variable "enable_logging" {
  type    = bool
  default = true
}

resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"

  dynamic "logging" {
    for_each = var.enable_logging ? [1] : []

    content {
      target_bucket = aws_s3_bucket.logs.id
      target_prefix = "logs/"
    }
  }
}
```

## Using with Maps

```hcl
variable "subnet_config" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
  }))
  default = {
    "public-1" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      public            = true
    }
    "private-1" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "us-east-1a"
      public            = false
    }
  }
}
```

## Best Practices

### 1. Use Locals to Prepare Data

```hcl
locals {
  ingress_rules = [
    for rule in var.raw_rules :
    {
      port        = rule.port
      protocol    = lookup(rule, "protocol", "tcp")
      cidr_blocks = lookup(rule, "cidrs", ["0.0.0.0/0"])
      description = lookup(rule, "description", "Managed by Terraform")
    }
  ]
}

dynamic "ingress" {
  for_each = local.ingress_rules
  # ...
}
```

### 2. Keep It Simple

Don't overuse dynamic blocks. If you only have 2-3 static blocks, write them explicitly:

```hcl
# Prefer this for simple cases
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}

ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

### 3. Use Meaningful Iterator Names

```hcl
# Good - clear what the iterator represents
dynamic "ingress" {
  for_each = local.security_rules
  iterator = rule

  content {
    from_port = rule.value.port
  }
}

# Avoid - confusing
dynamic "ingress" {
  for_each = local.security_rules
  iterator = x

  content {
    from_port = x.value.port
  }
}
```

### 4. Validate Input Data

```hcl
variable "ports" {
  type = list(number)

  validation {
    condition     = alltrue([for p in var.ports : p > 0 && p < 65536])
    error_message = "All ports must be between 1 and 65535."
  }
}
```

## Common Mistakes

### 1. Forgetting the `content` Block

```hcl
# Wrong - missing content block
dynamic "ingress" {
  for_each = var.rules
  from_port = ingress.value.port  # Error!
}

# Correct
dynamic "ingress" {
  for_each = var.rules
  content {
    from_port = ingress.value.port
  }
}
```

### 2. Using Wrong Iterator Reference

```hcl
# Wrong - using var instead of iterator
dynamic "ingress" {
  for_each = var.rules
  content {
    from_port = var.rules.port  # Error!
  }
}

# Correct
dynamic "ingress" {
  for_each = var.rules
  content {
    from_port = ingress.value.port
  }
}
```

### 3. Not Handling Empty Collections

```hcl
# This might fail if ports is empty and null
dynamic "ingress" {
  for_each = var.ports  # Could be null

  content {
    from_port = ingress.value
  }
}

# Better - handle potential null
dynamic "ingress" {
  for_each = var.ports != null ? var.ports : []

  content {
    from_port = ingress.value
  }
}
```

## Dynamic Blocks vs Other Approaches

| Approach | Use Case |
|----------|----------|
| Dynamic Blocks | Multiple nested blocks from a collection |
| `count` | Multiple resource instances |
| `for_each` | Multiple resource instances with keys |
| Static Blocks | Fixed number of known nested blocks |

## Complete Example

See the `main.tf` file in this directory for comprehensive working examples.

## Lab Exercise

Create a Terraform configuration that:
1. Uses dynamic blocks to create security group rules from a variable
2. Creates an EC2 instance with multiple EBS volumes using dynamic blocks
3. Implements conditional blocks based on environment
4. Uses nested dynamic blocks for a complex resource
5. Combines dynamic blocks with locals for data transformation
