# Terraform Lifecycle Rules

## What are Lifecycle Rules?

Lifecycle rules customize how Terraform creates, updates, and destroys resources. They provide fine-grained control over resource behavior.

## Lifecycle Block Syntax

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags]
    replace_triggered_by  = [aws_security_group.example.id]
  }
}
```

## create_before_destroy

Creates the new resource before destroying the old one. Essential for zero-downtime deployments.

### Default Behavior (Destroy Then Create)

```
1. Destroy old resource
2. Create new resource
   ↓
Potential downtime!
```

### With create_before_destroy

```
1. Create new resource
2. Update dependencies (load balancer, DNS, etc.)
3. Destroy old resource
   ↓
Zero downtime!
```

### Example

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "web-server"
  }
}
```

### Use Cases

- Web servers behind load balancers
- Database replicas
- Any resource where downtime is unacceptable

### Considerations

```hcl
# May need unique names to avoid conflicts
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"  # Use prefix instead of exact name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "app" {
  name_prefix = "app-role-"  # Allows creating new before deleting old

  lifecycle {
    create_before_destroy = true
  }
}
```

## prevent_destroy

Prevents Terraform from destroying the resource. Useful for protecting critical resources.

### Example

```hcl
resource "aws_db_instance" "production" {
  identifier        = "production-db"
  engine            = "mysql"
  instance_class    = "db.t3.medium"
  allocated_storage = 100

  lifecycle {
    prevent_destroy = true
  }
}
```

### Behavior

```bash
$ terraform destroy
Error: Instance cannot be destroyed

  on main.tf line 1:
   1: resource "aws_db_instance" "production" {

Resource aws_db_instance.production has lifecycle.prevent_destroy set,
but the plan calls for this resource to be destroyed.
```

### Use Cases

- Production databases
- S3 buckets with important data
- Resources that are expensive to recreate
- Resources with data that cannot be recovered

### Removing Protected Resources

To destroy a protected resource:
1. Remove `prevent_destroy = true` from the configuration
2. Run `terraform apply` to update the state
3. Then run `terraform destroy`

Or remove from state without destroying:
```bash
terraform state rm aws_db_instance.production
```

## ignore_changes

Tells Terraform to ignore changes to specific attributes. Useful when external processes modify resources.

### Basic Usage

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    ignore_changes = [
      tags,
      user_data,
    ]
  }
}
```

### Ignore All Changes

```hcl
resource "aws_instance" "managed_elsewhere" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    ignore_changes = all
  }
}
```

### Common Use Cases

#### Auto Scaling Groups (ignore desired_capacity)

```hcl
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = 1
  max_size            = 10
  desired_capacity    = 3  # Initial value
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      desired_capacity,  # Auto scaling changes this
      target_group_arns, # May be managed by other processes
    ]
  }
}
```

#### ECS Services (ignore task_definition)

```hcl
resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 3

  lifecycle {
    ignore_changes = [
      task_definition,  # Updated by CI/CD pipeline
      desired_count,    # Changed by auto scaling
    ]
  }
}
```

#### Tags Managed Externally

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server"
  }

  lifecycle {
    ignore_changes = [
      tags["LastModified"],      # Managed by external process
      tags["CostCenter"],        # Managed by billing team
    ]
  }
}
```

#### Kubernetes Resources

```hcl
resource "kubernetes_deployment" "app" {
  metadata {
    name = "app"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "myapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "myapp"
        }
      }

      spec {
        container {
          image = "myapp:v1"
          name  = "app"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].replicas,                    # HPA manages replicas
      spec[0].template[0].spec[0].container[0].image,  # CI/CD updates image
    ]
  }
}
```

## replace_triggered_by

Forces resource replacement when specified dependencies change. Added in Terraform 1.2.

### Basic Usage

```hcl
resource "aws_appautoscaling_target" "ecs" {
  # ... configuration ...

  lifecycle {
    replace_triggered_by = [
      aws_ecs_service.app.id
    ]
  }
}
```

### Example: Replace Instance When Security Group Changes

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

resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]

  lifecycle {
    replace_triggered_by = [
      aws_security_group.web.id  # Replace instance if SG changes
    ]
  }
}
```

### Example: Replace on Any Attribute Change

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    replace_triggered_by = [
      null_resource.always_replace.id  # Force replacement on every apply
    ]
  }
}

resource "null_resource" "always_replace" {
  triggers = {
    always = timestamp()
  }
}
```

## precondition and postcondition

Validation rules that run during planning (precondition) and after apply (postcondition).

### precondition Example

```hcl
variable "environment" {
  type = string
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition     = var.environment != "production" || var.instance_type != "t2.micro"
      error_message = "Production environment requires larger than t2.micro instance."
    }
  }
}
```

### postcondition Example

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  lifecycle {
    postcondition {
      condition     = self.public_ip != null
      error_message = "Instance must have a public IP address."
    }
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  lifecycle {
    postcondition {
      condition     = self.architecture == "x86_64"
      error_message = "AMI must be x86_64 architecture."
    }
  }
}
```

## Combining Lifecycle Rules

```hcl
resource "aws_db_instance" "production" {
  identifier           = "production-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  allocated_storage    = 100
  skip_final_snapshot  = false
  final_snapshot_identifier = "prod-db-final-snapshot"

  lifecycle {
    # Never accidentally destroy production database
    prevent_destroy = true

    # Allow storage autoscaling to change allocated_storage
    ignore_changes = [
      allocated_storage,
    ]

    # Ensure instance class meets minimum requirements
    precondition {
      condition     = can(regex("^db\\.(t3|r5|r6)", var.db_instance_class))
      error_message = "Production database requires t3, r5, or r6 class instances."
    }
  }
}
```

## Complete Example

```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  description = "Security group for web servers"

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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name        = "web-server"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      tags["LastUpdated"],
    ]

    replace_triggered_by = [
      aws_security_group.web.id
    ]

    precondition {
      condition     = can(regex("^ami-", var.ami_id))
      error_message = "AMI ID must start with 'ami-'."
    }

    postcondition {
      condition     = self.instance_state == "running"
      error_message = "Instance should be in running state."
    }
  }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.environment}-database"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "admin"
  password          = var.db_password
  skip_final_snapshot = var.environment != "production"

  lifecycle {
    prevent_destroy = var.environment == "production" ? true : false

    ignore_changes = [
      password,  # Managed externally
    ]
  }
}
```

## Best Practices

1. **Use `create_before_destroy`** for resources that need zero-downtime updates
2. **Use `prevent_destroy`** for critical resources like production databases
3. **Use `ignore_changes`** sparingly - it can hide important drift
4. **Document why** you're using each lifecycle rule
5. **Test lifecycle rules** in non-production environments first
6. **Use preconditions** to validate inputs early
7. **Use postconditions** to verify resource state after creation

## Lab Exercise

1. Create an EC2 instance with `create_before_destroy`
2. Change the AMI and observe the replacement behavior
3. Add `prevent_destroy` and try to destroy the resource
4. Add `ignore_changes` for tags and test tag modifications
