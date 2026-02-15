# Terraform Meta-Arguments

## What are Meta-Arguments?

Meta-arguments are special arguments that can be used with any resource type to change its behavior. They are not specific to any provider.

## Available Meta-Arguments

| Meta-Argument | Purpose |
|---------------|---------|
| `count` | Create multiple instances of a resource |
| `for_each` | Create multiple instances based on a map or set |
| `depends_on` | Explicitly specify dependencies |
| `provider` | Select a specific provider configuration |
| `lifecycle` | Customize resource lifecycle |

---

# count Meta-Argument

## Basic Usage

```hcl
resource "aws_instance" "server" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "server-${count.index}"
  }
}
```

This creates 3 instances named:
- server-0
- server-1
- server-2

## count.index

`count.index` gives the current iteration number (starting from 0).

```hcl
resource "aws_instance" "web" {
  count         = 5
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name  = "web-server-${count.index + 1}"  # 1-based naming
    Index = count.index
  }
}
```

## Conditional Resource Creation

```hcl
variable "create_instance" {
  type    = bool
  default = true
}

resource "aws_instance" "optional" {
  count         = var.create_instance ? 1 : 0
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

## Using count with Lists

```hcl
variable "instance_names" {
  type    = list(string)
  default = ["web", "app", "db"]
}

resource "aws_instance" "server" {
  count         = length(var.instance_names)
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = var.instance_names[count.index]
  }
}
```

## Referencing count Resources

```hcl
# Single instance from the list
output "first_instance_id" {
  value = aws_instance.server[0].id
}

# All instance IDs (splat expression)
output "all_instance_ids" {
  value = aws_instance.server[*].id
}

# All public IPs
output "all_public_ips" {
  value = aws_instance.server[*].public_ip
}
```

## count with Subnets

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}
```

## count Limitations

1. **Index-based**: Resources are identified by index
2. **Order matters**: Removing an item in the middle shifts indices
3. **Can't use with for_each**: Use one or the other

### Problem Example

```hcl
# Original
variable "names" {
  default = ["web", "app", "db"]
}

# server[0] = web
# server[1] = app
# server[2] = db

# After removing "app"
variable "names" {
  default = ["web", "db"]
}

# server[0] = web (unchanged)
# server[1] = db (was server[2]!)
# Terraform will destroy server[1] (app) AND modify server[2] (db) -> server[1]
```

---

# for_each Meta-Argument

## Basic Usage

```hcl
resource "aws_instance" "server" {
  for_each = toset(["web", "app", "db"])

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = each.key
  }
}
```

Creates instances:
- aws_instance.server["web"]
- aws_instance.server["app"]
- aws_instance.server["db"]

## each.key and each.value

```hcl
# With a Set - key and value are the same
resource "aws_instance" "server" {
  for_each = toset(["web", "app", "db"])

  tags = {
    Name = each.key    # "web", "app", "db"
    Role = each.value  # same as each.key
  }
}

# With a Map - key and value are different
resource "aws_instance" "server" {
  for_each = {
    web = "t2.micro"
    app = "t2.small"
    db  = "t2.medium"
  }

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value  # "t2.micro", "t2.small", "t2.medium"

  tags = {
    Name = each.key  # "web", "app", "db"
  }
}
```

## for_each with Complex Maps

```hcl
variable "servers" {
  type = map(object({
    instance_type = string
    ami           = string
    subnet_id     = string
  }))
  default = {
    web = {
      instance_type = "t2.micro"
      ami           = "ami-web123"
      subnet_id     = "subnet-public"
    }
    app = {
      instance_type = "t2.small"
      ami           = "ami-app123"
      subnet_id     = "subnet-private"
    }
    db = {
      instance_type = "t2.medium"
      ami           = "ami-db123"
      subnet_id     = "subnet-database"
    }
  }
}

resource "aws_instance" "server" {
  for_each = var.servers

  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnet_id

  tags = {
    Name = each.key
  }
}
```

## Referencing for_each Resources

```hcl
# Specific instance
output "web_server_ip" {
  value = aws_instance.server["web"].public_ip
}

# All instances as a map
output "all_server_ips" {
  value = {
    for name, instance in aws_instance.server :
    name => instance.public_ip
  }
}

# All IDs as a list
output "all_server_ids" {
  value = values(aws_instance.server)[*].id
}
```

## Converting Lists to Sets

```hcl
variable "subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "aws_subnet" "private" {
  for_each   = toset(var.subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = each.key

  tags = {
    Name = "private-${each.key}"
  }
}
```

## for_each with Data Sources

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  for_each = toset(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(data.aws_availability_zones.available.names, each.key))
  availability_zone = each.key

  tags = {
    Name = "public-${each.key}"
  }
}
```

## for_each Advantages Over count

1. **Named instances**: Resources identified by name, not index
2. **Order independent**: Adding/removing items doesn't affect others
3. **Self-documenting**: Clear what each resource represents

### Comparison

```hcl
# With count - fragile ordering
resource "aws_instance" "server" {
  count = length(var.names)
  # ...
}
# aws_instance.server[0], aws_instance.server[1], etc.

# With for_each - stable naming
resource "aws_instance" "server" {
  for_each = toset(var.names)
  # ...
}
# aws_instance.server["web"], aws_instance.server["app"], etc.
```

---

# Combining count and for_each

You **cannot** use both `count` and `for_each` on the same resource, but you can use them in different resources.

```hcl
# Module with count
module "vpc" {
  count  = var.create_vpc ? 1 : 0
  source = "./modules/vpc"
}

# Resource with for_each
resource "aws_instance" "server" {
  for_each = var.servers
  # ...
}
```

---

# provider Meta-Argument

Select which provider configuration to use.

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_instance" "east" {
  ami           = "ami-east123"
  instance_type = "t2.micro"
  # Uses default provider
}

resource "aws_instance" "west" {
  provider      = aws.west  # Uses aliased provider
  ami           = "ami-west123"
  instance_type = "t2.micro"
}
```

---

# depends_on Meta-Argument

Explicitly define dependencies that Terraform can't infer automatically.

```hcl
resource "aws_iam_role_policy" "example" {
  name   = "example"
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # Instance needs the IAM policy to be ready
  depends_on = [aws_iam_role_policy.example]
}
```

---

# Complete Examples

## Example 1: Multi-Environment Setup

```hcl
variable "environments" {
  type = map(object({
    instance_count = number
    instance_type  = string
  }))
  default = {
    dev = {
      instance_count = 1
      instance_type  = "t2.micro"
    }
    staging = {
      instance_count = 2
      instance_type  = "t2.small"
    }
    prod = {
      instance_count = 3
      instance_type  = "t2.medium"
    }
  }
}

resource "aws_instance" "env_servers" {
  for_each = var.environments

  count         = each.value.instance_count  # ERROR! Can't combine
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value.instance_type
}

# Correct approach: Flatten the structure
locals {
  instances = flatten([
    for env, config in var.environments : [
      for i in range(config.instance_count) : {
        name          = "${env}-${i + 1}"
        environment   = env
        instance_type = config.instance_type
      }
    ]
  ])
}

resource "aws_instance" "servers" {
  for_each = { for inst in local.instances : inst.name => inst }

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value.instance_type

  tags = {
    Name        = each.key
    Environment = each.value.environment
  }
}
```

## Example 2: IAM Users with Policies

```hcl
variable "users" {
  type = map(object({
    groups   = list(string)
    policies = list(string)
  }))
  default = {
    alice = {
      groups   = ["developers", "admins"]
      policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    bob = {
      groups   = ["developers"]
      policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
  }
}

resource "aws_iam_user" "users" {
  for_each = var.users
  name     = each.key
}

resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each = {
    for pair in flatten([
      for user, config in var.users : [
        for policy in config.policies : {
          user   = user
          policy = policy
        }
      ]
    ]) : "${pair.user}-${pair.policy}" => pair
  }

  user       = aws_iam_user.users[each.value.user].name
  policy_arn = each.value.policy
}
```

## Example 3: Security Group Rules

```hcl
variable "security_rules" {
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH from internal"
    },
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    }
  ]
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "web_rules" {
  for_each = { for idx, rule in var.security_rules : "${rule.type}-${rule.from_port}" => rule }

  security_group_id = aws_security_group.web.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}
```

## Best Practices

1. **Prefer for_each over count** for named resources
2. **Use count for conditional creation** (count = var.enabled ? 1 : 0)
3. **Use toset()** when converting lists to use with for_each
4. **Create unique keys** when using for_each with complex objects
5. **Avoid count with lists** that may change order
6. **Document meta-argument usage** for team understanding

## Lab Exercise

1. Create 3 EC2 instances using count
2. Create EC2 instances using for_each with a map of configurations
3. Create conditional resources based on environment variable
4. Create security group rules using for_each
