# Terraform Local Values (locals)

## What are Local Values?

Local values (locals) are named expressions that can be used multiple times within a Terraform module. They help simplify configurations by avoiding repeated expressions and making code more readable and maintainable.

## Key Characteristics

- **DRY Principle**: Define once, use multiple times
- **Computed Values**: Can combine variables, resource attributes, and functions
- **Module Scoped**: Only accessible within the module where they're defined
- **No External Input**: Unlike variables, locals cannot be set from outside the module

## Basic Syntax

```hcl
locals {
  local_name = "value"
}

# Reference using local.local_name
resource "aws_instance" "example" {
  tags = {
    Name = local.local_name
  }
}
```

## Defining Local Values

### Simple Values

```hcl
locals {
  # String
  environment = "production"

  # Number
  instance_count = 3

  # Boolean
  enable_monitoring = true

  # List
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Map
  common_tags = {
    Project     = "MyApp"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

### Computed Values

```hcl
variable "project_name" {
  default = "myapp"
}

variable "environment" {
  default = "dev"
}

locals {
  # Combining variables
  name_prefix = "${var.project_name}-${var.environment}"

  # Using expressions
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"

  # Using functions
  timestamp = formatdate("YYYY-MM-DD", timestamp())

  # Complex expressions
  resource_name = lower(replace("${var.project_name}-${var.environment}", "_", "-"))
}
```

### Multiple locals Blocks

You can have multiple `locals` blocks in your configuration:

```hcl
locals {
  environment = "production"
  region      = "us-east-1"
}

locals {
  # Reference other locals
  bucket_name = "app-data-${local.environment}-${local.region}"
}
```

## Common Use Cases

### 1. Common Tags

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.team
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    CreatedAt   = timestamp()
  }
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-server"
    Role = "webserver"
  })
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data-bucket"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-data-bucket"
  })
}
```

### 2. Resource Naming Convention

```hcl
locals {
  name_prefix = "${var.company}-${var.project}-${var.environment}"

  resource_names = {
    vpc             = "${local.name_prefix}-vpc"
    public_subnet   = "${local.name_prefix}-public-subnet"
    private_subnet  = "${local.name_prefix}-private-subnet"
    security_group  = "${local.name_prefix}-sg"
    instance        = "${local.name_prefix}-instance"
    load_balancer   = "${local.name_prefix}-alb"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = local.resource_names.vpc
  }
}

resource "aws_security_group" "main" {
  name   = local.resource_names.security_group
  vpc_id = aws_vpc.main.id
}
```

### 3. Conditional Logic

```hcl
locals {
  # Environment-based settings
  is_production = var.environment == "prod"

  instance_type = local.is_production ? "t3.large" : "t3.micro"
  instance_count = local.is_production ? 3 : 1

  # Enable features based on environment
  enable_enhanced_monitoring = local.is_production
  enable_deletion_protection = local.is_production

  # Storage settings
  storage_config = {
    size      = local.is_production ? 100 : 20
    type      = local.is_production ? "gp3" : "gp2"
    encrypted = local.is_production
  }
}
```

### 4. Data Transformation

```hcl
variable "subnet_config" {
  default = {
    public  = ["10.0.1.0/24", "10.0.2.0/24"]
    private = ["10.0.10.0/24", "10.0.11.0/24"]
  }
}

locals {
  # Flatten subnets for iteration
  all_subnets = concat(
    var.subnet_config.public,
    var.subnet_config.private
  )

  # Create subnet map with metadata
  subnet_details = {
    for idx, cidr in local.all_subnets :
    "subnet-${idx}" => {
      cidr       = cidr
      type       = idx < length(var.subnet_config.public) ? "public" : "private"
      az_index   = idx % 2
    }
  }
}
```

### 5. CIDR Calculations

```hcl
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

locals {
  # Calculate subnet CIDRs from VPC CIDR
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),   # 10.0.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2),   # 10.0.2.0/24
    cidrsubnet(var.vpc_cidr, 8, 3)    # 10.0.3.0/24
  ]

  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 10),  # 10.0.10.0/24
    cidrsubnet(var.vpc_cidr, 8, 11),  # 10.0.11.0/24
    cidrsubnet(var.vpc_cidr, 8, 12)   # 10.0.12.0/24
  ]
}
```

### 6. Working with Files

```hcl
locals {
  # Read and parse JSON file
  config = jsondecode(file("${path.module}/config.json"))

  # Read and parse YAML file
  settings = yamldecode(file("${path.module}/settings.yaml"))

  # Template rendering
  user_data = templatefile("${path.module}/user-data.sh", {
    environment = var.environment
    app_version = var.app_version
  })
}
```

## locals vs Variables

| Feature | Variables | Locals |
|---------|-----------|--------|
| External Input | Yes | No |
| Set via CLI | Yes (-var) | No |
| Set via tfvars | Yes | No |
| Computed Values | Limited | Yes |
| Can Reference Resources | No | Yes |
| Module Parameters | Yes | No |
| DRY Code | Partial | Yes |

## When to Use locals

✅ **Use locals when:**
- You need to compute values from variables or resources
- You want to avoid repeating the same expression
- You need conditional logic for values
- You want to simplify complex expressions
- You need to transform or combine data

❌ **Don't use locals when:**
- The value should be configurable from outside the module (use variables)
- You're just aliasing a simple value without transformation
- The value is only used once

## Best Practices

### 1. Group Related Locals

```hcl
# Naming locals
locals {
  name_prefix   = "${var.project}-${var.environment}"
  resource_name = lower(local.name_prefix)
}

# Tag locals
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Network locals
locals {
  vpc_cidr     = "10.0.0.0/16"
  subnet_cidrs = cidrsubnets(local.vpc_cidr, 4, 4, 4)
}
```

### 2. Use Descriptive Names

```hcl
# Good
locals {
  is_production_environment = var.environment == "prod"
  database_connection_string = "postgresql://${var.db_host}:${var.db_port}/${var.db_name}"
}

# Avoid
locals {
  flag = var.environment == "prod"
  str  = "postgresql://${var.db_host}:${var.db_port}/${var.db_name}"
}
```

### 3. Document Complex Locals

```hcl
locals {
  # Calculate the number of instances per availability zone
  # ensuring even distribution across zones
  instances_per_az = ceil(var.total_instances / length(var.availability_zones))
}
```

## Complete Example

See the `main.tf` file in this directory for a complete working example.

## Lab Exercise

Create a Terraform configuration that:
1. Uses locals to define a consistent naming convention
2. Creates common tags that are applied to all resources
3. Uses conditional locals based on environment
4. Computes subnet CIDRs from a VPC CIDR
5. Transforms a list of server configurations into a map
