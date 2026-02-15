# Mutable vs Immutable Infrastructure

## Overview

Understanding mutable vs immutable infrastructure is fundamental to modern DevOps practices and directly impacts how you use Terraform.

## Mutable Infrastructure

### Definition
Infrastructure that is updated in-place after deployment. Changes are applied to existing servers/resources.

### Traditional Approach

```
Server Creation → Configure → Update → Update → Update...
     ↓              ↓          ↓        ↓        ↓
   Day 0         Day 1      Day 30   Day 60   Day 90

Same server, different states over time
```

### Characteristics

- Servers are updated with patches, software updates
- Configuration changes are applied to running systems
- Servers evolve over time
- Each server may have a unique history

### Problems with Mutable Infrastructure

1. **Configuration Drift**
   - Servers diverge from desired state over time
   - Manual changes accumulate
   - Difficult to reproduce environments

2. **Snowflake Servers**
   - Each server becomes unique
   - "It works on that server but not this one"
   - Hard to troubleshoot

3. **Update Failures**
   - Partial updates can leave servers in broken state
   - Rollbacks are complex
   - Downtime during updates

### Example: Mutable Update Pattern

```hcl
# Traditional mutable approach - updating in place
resource "aws_instance" "web" {
  ami           = "ami-old-version"
  instance_type = "t2.micro"

  # Updates to user_data don't recreate by default
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              EOF
}

# Later, you SSH in and run more commands:
# sudo yum install new-package
# sudo vim /etc/httpd/conf/httpd.conf
# These changes are not tracked!
```

## Immutable Infrastructure

### Definition
Infrastructure that is never modified after deployment. Any changes require replacing the entire resource with a new version.

### Modern Approach

```
Server v1 → (need change) → Create Server v2 → Destroy Server v1
                                   ↓
                            Fresh, consistent state
```

### Characteristics

- Servers are never updated after creation
- Changes = new resource deployment
- Old resources are destroyed
- Every deployment is a fresh start

### Benefits of Immutable Infrastructure

1. **Consistency**
   - Every instance is identical
   - No configuration drift
   - Reproducible environments

2. **Reliability**
   - Tested image deployed as-is
   - No partial update failures
   - Easy rollbacks (deploy previous version)

3. **Simplicity**
   - No complex update scripts
   - Clear deployment process
   - Easier debugging

4. **Security**
   - Fresh instances with latest patches
   - No accumulated vulnerabilities
   - Known, auditable state

## Terraform and Immutability

### How Terraform Handles Changes

Terraform determines if a change requires:
1. **Update in-place** (mutable behavior)
2. **Replace** (immutable behavior)

### Example: In-Place Update

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"  # Change to t2.small

  tags = {
    Name = "web-server"  # Change to "web-server-updated"
  }
}
```

```
# terraform plan output:
~ resource "aws_instance" "web" {
    ~ instance_type = "t2.micro" -> "t2.small"
    ~ tags = {
        ~ Name = "web-server" -> "web-server-updated"
      }
  }

Plan: 0 to add, 1 to change, 0 to destroy.
```

### Example: Force Replacement

```hcl
resource "aws_instance" "web" {
  ami           = "ami-NEW-VERSION"  # Changing AMI forces replacement
  instance_type = "t2.micro"
}
```

```
# terraform plan output:
-/+ resource "aws_instance" "web" {
      ~ ami           = "ami-0c55b159cbfafe1f0" -> "ami-NEW-VERSION" # forces replacement
      ~ id            = "i-abc123" -> (known after apply)
        instance_type = "t2.micro"
  }

Plan: 1 to add, 0 to change, 1 to destroy.
```

### Force Replacement Attributes

Some attributes always force replacement when changed:

**AWS EC2 Instance:**
- `ami`
- `availability_zone`
- `key_name`
- `subnet_id` (when not using network interface)

**AWS RDS Instance:**
- `identifier`
- `engine`
- `availability_zone`

### Using lifecycle to Control Behavior

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    # Create new resource before destroying old one
    create_before_destroy = true
  }
}
```

## Implementing Immutable Infrastructure with Terraform

### Pattern 1: AMI-Based Deployments

```hcl
# Build AMI with Packer (outside Terraform)
# Then reference it in Terraform

variable "ami_version" {
  description = "Version of the AMI to deploy"
  default     = "v1.2.3"
}

data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["my-app-${var.ami_version}"]
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.app.id  # Changing version = new AMI = replacement
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}
```

### Pattern 2: Auto Scaling with Launch Templates

```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Bootstrap script baked into template
              /opt/app/start.sh
              EOF
  )
}

resource "aws_autoscaling_group" "app" {
  name                = "app-${aws_launch_template.app.latest_version}"
  desired_capacity    = 3
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}
```

### Pattern 3: Container-Based Immutability

```hcl
resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "myrepo/myapp:${var.image_tag}"  # New tag = new task definition
      portMappings = [
        {
          containerPort = 8080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 50
  }
}
```

### Pattern 4: Blue-Green Deployments

```hcl
variable "active_color" {
  description = "Which environment is active (blue or green)"
  default     = "blue"
}

resource "aws_instance" "blue" {
  count         = var.active_color == "blue" ? var.instance_count : 0
  ami           = var.blue_ami
  instance_type = "t2.micro"

  tags = {
    Color = "blue"
  }
}

resource "aws_instance" "green" {
  count         = var.active_color == "green" ? var.instance_count : 0
  ami           = var.green_ami
  instance_type = "t2.micro"

  tags = {
    Color = "green"
  }
}

resource "aws_lb_target_group_attachment" "active" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.active_color == "blue" ? aws_instance.blue[count.index].id : aws_instance.green[count.index].id
  port             = 80
}
```

## Comparison Summary

| Aspect | Mutable | Immutable |
|--------|---------|-----------|
| Updates | In-place | Replace entire resource |
| State | Evolves over time | Fresh each deployment |
| Drift | Common problem | Eliminated |
| Rollback | Complex | Deploy previous version |
| Debugging | Harder (unique history) | Easier (consistent state) |
| Tools | SSH, config management | Image builders, containers |
| Downtime | During updates | Minimized with blue-green |

## Best Practices

1. **Prefer immutable patterns** when possible
2. **Use `create_before_destroy`** for zero-downtime deployments
3. **Build images with tools like Packer** instead of configuring post-creation
4. **Use containers** for application-level immutability
5. **Implement proper health checks** before switching traffic
6. **Automate image building** in CI/CD pipelines

## Lab Exercise

1. Create an EC2 instance with Terraform
2. Change the AMI and observe the replacement behavior
3. Implement `create_before_destroy` lifecycle rule
4. Create a simple blue-green deployment setup
