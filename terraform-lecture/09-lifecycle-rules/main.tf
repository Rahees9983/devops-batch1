# ===========================================
# Lifecycle Rules - Complete Examples
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  default = "demo"
}

variable "ami_id" {
  default = "ami-0c55b159cbfafe1f0"
}

# ===========================================
# create_before_destroy
# Creates new resource before destroying old one
# ===========================================

resource "aws_security_group" "create_before" {
  name_prefix = "${var.environment}-web-"  # Use prefix for uniqueness
  description = "Demo of create_before_destroy"

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

  tags = {
    Name    = "${var.environment}-create-before"
    Example = "create_before_destroy"
  }
}

resource "aws_instance" "create_before" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.create_before.id]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "${var.environment}-create-before"
    Example = "create_before_destroy"
  }
}

# ===========================================
# prevent_destroy
# Prevents accidental destruction
# ===========================================

resource "aws_s3_bucket" "protected" {
  bucket = "${var.environment}-protected-bucket-${random_id.bucket.hex}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name     = "${var.environment}-protected"
    Example  = "prevent_destroy"
    Critical = "true"
  }
}

resource "random_id" "bucket" {
  byte_length = 4
}

# Note: To destroy this bucket, you must:
# 1. Remove prevent_destroy = true
# 2. Run terraform apply
# 3. Then run terraform destroy

# ===========================================
# ignore_changes
# Ignores changes to specific attributes
# ===========================================

resource "aws_instance" "ignore_changes" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  tags = {
    Name        = "${var.environment}-ignore-changes"
    LastUpdated = "2024-01-01"  # This will be ignored
    CostCenter  = "12345"       # This will be ignored
  }

  lifecycle {
    ignore_changes = [
      tags["LastUpdated"],
      tags["CostCenter"],
      # user_data,  # Uncomment to ignore user_data changes
    ]
  }
}

# Example: Auto Scaling Group with ignored capacity
resource "aws_launch_template" "asg_demo" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================
# ignore_changes = all
# Ignores ALL changes (resource managed elsewhere)
# ===========================================

resource "aws_instance" "ignore_all" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  lifecycle {
    ignore_changes = all  # Ignore all attribute changes
  }

  tags = {
    Name    = "${var.environment}-ignore-all"
    Example = "ignore_changes_all"
  }
}

# ===========================================
# replace_triggered_by
# Forces replacement when dependency changes
# ===========================================

resource "aws_security_group" "trigger" {
  name_prefix = "${var.environment}-trigger-"
  description = "Changes to this SG will trigger instance replacement"

  ingress {
    from_port   = 22
    to_port     = 22
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

  tags = {
    Name = "${var.environment}-trigger-sg"
  }
}

resource "aws_instance" "replace_triggered" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.trigger.id]

  lifecycle {
    # Replace instance when security group changes
    replace_triggered_by = [
      aws_security_group.trigger.id
    ]
  }

  tags = {
    Name    = "${var.environment}-replace-triggered"
    Example = "replace_triggered_by"
  }
}

# ===========================================
# precondition
# Validates before resource creation
# ===========================================

variable "instance_type_precondition" {
  description = "Instance type for precondition example"
  default     = "t2.micro"
}

resource "aws_instance" "precondition" {
  ami           = var.ami_id
  instance_type = var.instance_type_precondition

  lifecycle {
    precondition {
      condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type_precondition)
      error_message = "Instance type must be t2.micro, t2.small, or t2.medium for this environment."
    }
  }

  tags = {
    Name    = "${var.environment}-precondition"
    Example = "precondition"
  }
}

# ===========================================
# postcondition
# Validates after resource creation
# ===========================================

resource "aws_instance" "postcondition" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true

  lifecycle {
    postcondition {
      condition     = self.public_ip != null && self.public_ip != ""
      error_message = "Instance must have a public IP address assigned."
    }
  }

  tags = {
    Name    = "${var.environment}-postcondition"
    Example = "postcondition"
  }
}

# ===========================================
# Combined Lifecycle Rules
# ===========================================

resource "aws_instance" "combined" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  tags = {
    Name        = "${var.environment}-combined"
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = "2024-01-01"  # Will be ignored
  }

  lifecycle {
    # Create new before destroying old
    create_before_destroy = true

    # Ignore certain tag changes
    ignore_changes = [
      tags["CreatedAt"],
    ]

    # Validate instance type
    precondition {
      condition     = can(regex("^t2\\.", var.instance_type_precondition)) || can(regex("^t3\\.", var.instance_type_precondition))
      error_message = "Must use t2 or t3 instance types."
    }

    # Validate instance state after creation
    postcondition {
      condition     = self.instance_state == "running"
      error_message = "Instance should be in running state."
    }
  }
}

# ===========================================
# Database with prevent_destroy
# ===========================================

/*
# Uncomment to test - WARNING: This will create real RDS resources!

resource "aws_db_instance" "protected_db" {
  identifier        = "${var.environment}-protected-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "myapp"
  username = "admin"
  password = "changeme123!"

  skip_final_snapshot = var.environment != "prod"

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      password,  # Password managed externally
    ]
  }

  tags = {
    Name = "${var.environment}-protected-db"
  }
}
*/

# ===========================================
# Outputs
# ===========================================

output "create_before_instance_id" {
  value = aws_instance.create_before.id
}

output "protected_bucket_name" {
  value = aws_s3_bucket.protected.id
}

output "lifecycle_rules_summary" {
  value = <<-EOT

    LIFECYCLE RULES DEMONSTRATED:

    1. create_before_destroy = true
       - New resource created before old one destroyed
       - Enables zero-downtime deployments
       - Use with name_prefix for unique names

    2. prevent_destroy = true
       - Prevents accidental destruction
       - Must be removed to destroy resource
       - Use for critical resources (databases, S3)

    3. ignore_changes = [attributes]
       - Ignores changes to listed attributes
       - Useful for externally managed attributes
       - Use 'all' to ignore everything

    4. replace_triggered_by = [resources]
       - Forces replacement when dependencies change
       - Useful for configuration dependencies

    5. precondition { }
       - Validates BEFORE creation
       - Catches configuration errors early

    6. postcondition { }
       - Validates AFTER creation
       - Ensures resource state is correct

  EOT
}
