# ===========================================
# Mutable vs Immutable Infrastructure Examples
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

variable "ami_version" {
  description = "Version of the AMI to use"
  default     = "v1"
}

# ===========================================
# MUTABLE EXAMPLE
# Changes are applied in-place
# ===========================================

# Changing instance_type = in-place update (mutable)
resource "aws_instance" "mutable_example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"  # Try changing to t2.small

  # Tags can be changed in-place (mutable)
  tags = {
    Name    = "${var.environment}-mutable-instance"
    Version = "1.0"
  }

  # user_data changes cause replacement by default
  # but this shows mutable behavior for tags/instance_type
}

# ===========================================
# IMMUTABLE EXAMPLE - AMI Change
# Changing AMI forces recreation
# ===========================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "immutable_ami" {
  ami           = data.aws_ami.amazon_linux.id  # Changing AMI = replacement
  instance_type = "t2.micro"

  tags = {
    Name    = "${var.environment}-immutable-ami"
    Version = var.ami_version
  }
}

# ===========================================
# IMMUTABLE with create_before_destroy
# Zero downtime replacement
# ===========================================

resource "aws_instance" "zero_downtime" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name    = "${var.environment}-zero-downtime"
    Version = var.ami_version
  }

  lifecycle {
    # Create new instance BEFORE destroying old one
    create_before_destroy = true
  }
}

# ===========================================
# IMMUTABLE - Security Group
# Using name_prefix for create_before_destroy
# ===========================================

resource "aws_security_group" "immutable_sg" {
  name_prefix = "${var.environment}-sg-"  # Using prefix allows recreation
  description = "Security group with immutable pattern"

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
    Name = "${var.environment}-immutable-sg"
  }
}

# ===========================================
# BLUE-GREEN DEPLOYMENT PATTERN
# Full immutable deployment
# ===========================================

variable "active_color" {
  description = "Which deployment is active (blue or green)"
  default     = "blue"
}

variable "blue_ami" {
  description = "AMI for blue deployment"
  default     = "ami-0c55b159cbfafe1f0"
}

variable "green_ami" {
  description = "AMI for green deployment"
  default     = "ami-0c55b159cbfafe1f0"
}

# Blue instances
resource "aws_instance" "blue" {
  count = var.active_color == "blue" ? 2 : 0

  ami           = var.blue_ami
  instance_type = "t2.micro"

  tags = {
    Name  = "${var.environment}-blue-${count.index + 1}"
    Color = "blue"
  }
}

# Green instances
resource "aws_instance" "green" {
  count = var.active_color == "green" ? 2 : 0

  ami           = var.green_ami
  instance_type = "t2.micro"

  tags = {
    Name  = "${var.environment}-green-${count.index + 1}"
    Color = "green"
  }
}

# ===========================================
# LAUNCH TEMPLATE for Auto Scaling (Immutable)
# ===========================================

resource "aws_launch_template" "immutable" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Version: ${var.ami_version}"
              yum update -y
              yum install -y httpd
              systemctl start httpd
              echo "Hello from ${var.ami_version}" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.environment}-immutable-instance"
      Version = var.ami_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================
# Outputs
# ===========================================

output "mutable_instance_id" {
  value = aws_instance.mutable_example.id
}

output "immutable_instance_id" {
  value = aws_instance.immutable_ami.id
}

output "zero_downtime_instance_id" {
  value = aws_instance.zero_downtime.id
}

output "active_deployment" {
  value = var.active_color
}

output "blue_instance_ids" {
  value = aws_instance.blue[*].id
}

output "green_instance_ids" {
  value = aws_instance.green[*].id
}

output "explanation" {
  value = <<-EOT

    MUTABLE CHANGES (in-place):
    - instance_type: t2.micro -> t2.small
    - tags: any tag changes
    - monitoring: enabled/disabled

    IMMUTABLE CHANGES (replacement):
    - ami: any change forces new instance
    - availability_zone: any change forces new
    - subnet_id: any change forces new

    Use 'terraform plan' to see which changes are in-place vs replacement.

    Symbol meanings:
    ~ = in-place update (mutable)
    -/+ = destroy then create (immutable)
    +/- = create then destroy (immutable with create_before_destroy)

  EOT
}
