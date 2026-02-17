# ===========================================
# Terraform Dynamic Blocks - Main Configuration
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

# ===========================================
# Variables
# ===========================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "dynamic-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# Security group rules variable
variable "ingress_rules" {
  description = "List of ingress rules for security group"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH from internal network"
    },
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere"
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    },
    {
      port        = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Application port from internal"
    }
  ]
}

# EBS volumes variable
variable "ebs_volumes" {
  description = "List of EBS volumes to attach"
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
    encrypted   = bool
  }))
  default = [
    {
      device_name = "/dev/sdb"
      volume_size = 50
      volume_type = "gp3"
      encrypted   = true
    },
    {
      device_name = "/dev/sdc"
      volume_size = 100
      volume_type = "gp3"
      encrypted   = true
    }
  ]
}

# Tags variable for ASG
variable "asg_tags" {
  description = "Tags for Auto Scaling Group"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "dynamic-demo"
    ManagedBy   = "Terraform"
    Team        = "DevOps"
  }
}

# Port ranges variable
variable "port_ranges" {
  description = "Port ranges for security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 3000
      to_port     = 3010
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Application port range"
    },
    {
      from_port   = 8000
      to_port     = 8100
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Microservices port range"
    }
  ]
}

# Enable features
variable "enable_logging" {
  description = "Enable S3 bucket logging"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable S3 bucket encryption"
  type        = bool
  default     = true
}

# ===========================================
# Locals
# ===========================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Prepare ingress rules with defaults
  processed_ingress_rules = [
    for rule in var.ingress_rules : {
      from_port   = rule.port
      to_port     = rule.port
      protocol    = rule.protocol
      cidr_blocks = rule.cidr_blocks
      description = rule.description
    }
  ]

  # Combined rules (single ports + port ranges)
  all_ingress_rules = concat(
    local.processed_ingress_rules,
    [
      for range in var.port_ranges : {
        from_port   = range.from_port
        to_port     = range.to_port
        protocol    = range.protocol
        cidr_blocks = range.cidr_blocks
        description = range.description
      }
    ]
  )

  # IAM policy statements
  iam_statements = [
    {
      sid       = "S3Access"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::${local.name_prefix}-*"]
    },
    {
      sid       = "CloudWatchLogs"
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["arn:aws:logs:*:*:*"]
    },
    {
      sid       = "SSMAccess"
      effect    = "Allow"
      actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
      resources = ["arn:aws:ssm:*:*:parameter/${var.project_name}/*"]
    }
  ]

  # Notification configuration
  notifications = var.environment == "prod" ? [
    {
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "uploads/"
      filter_suffix = ".json"
    },
    {
      events        = ["s3:ObjectRemoved:*"]
      filter_prefix = "data/"
      filter_suffix = ""
    }
  ] : []
}

# ===========================================
# Data Sources
# ===========================================

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ===========================================
# Provider
# ===========================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ===========================================
# Example 1: Security Group with Dynamic Ingress
# ===========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.name_prefix}-subnet"
  }
}

# Security Group with Dynamic Ingress Rules
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group with dynamic ingress rules"
  vpc_id      = aws_vpc.main.id

  # Dynamic block for ingress rules
  dynamic "ingress" {
    for_each = local.all_ingress_rules

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  # Static egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

# ===========================================
# Example 2: EC2 with Dynamic EBS Volumes
# ===========================================

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.main.id

  vpc_security_group_ids = [aws_security_group.web.id]

  # Root volume
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${local.name_prefix}-root"
    }
  }

  # Dynamic EBS volumes
  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes

    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      volume_type           = ebs_block_device.value.volume_type
      encrypted             = ebs_block_device.value.encrypted
      delete_on_termination = true

      tags = {
        Name = "${local.name_prefix}-ebs-${ebs_block_device.key}"
      }
    }
  }

  tags = {
    Name = "${local.name_prefix}-app-server"
  }
}

# ===========================================
# Example 3: Dynamic Tags for ASG
# ===========================================

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-asg-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-asg"
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.main.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Dynamic tags for ASG instances
  dynamic "tag" {
    for_each = var.asg_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Additional static tag
  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg-instance"
    propagate_at_launch = true
  }
}

# ===========================================
# Example 4: IAM Policy with Dynamic Statements
# ===========================================

data "aws_iam_policy_document" "app_policy" {
  # Dynamic policy statements
  dynamic "statement" {
    for_each = local.iam_statements

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_policy" "app" {
  name        = "${local.name_prefix}-app-policy"
  description = "Application policy with dynamic statements"
  policy      = data.aws_iam_policy_document.app_policy.json
}

# ===========================================
# Example 5: Conditional Dynamic Blocks
# ===========================================

resource "aws_s3_bucket" "data" {
  bucket = "${local.name_prefix}-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${local.name_prefix}-data-bucket"
  }
}

# Conditional versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Conditional encryption using dynamic block
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ===========================================
# Example 6: Security Group with Iterator
# ===========================================

variable "service_ports" {
  description = "Map of service ports"
  type = map(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    ssh = {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
    http = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    https = {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    mysql = {
      port        = 3306
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  }
}

resource "aws_security_group" "services" {
  name        = "${local.name_prefix}-services-sg"
  description = "Security group with named service ports"
  vpc_id      = aws_vpc.main.id

  # Using custom iterator name
  dynamic "ingress" {
    for_each = var.service_ports
    iterator = service  # Custom iterator name

    content {
      from_port   = service.value.port
      to_port     = service.value.port
      protocol    = service.value.protocol
      cidr_blocks = service.value.cidr_blocks
      description = "Allow ${service.key} traffic"  # Using the key (service name)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-services-sg"
  }
}

# ===========================================
# Example 7: Multiple Subnets with Dynamic Blocks
# ===========================================

variable "subnet_config" {
  description = "Subnet configuration"
  type = map(object({
    cidr_index = number
    type       = string
    public_ip  = bool
  }))
  default = {
    "public-1" = {
      cidr_index = 1
      type       = "public"
      public_ip  = true
    }
    "public-2" = {
      cidr_index = 2
      type       = "public"
      public_ip  = true
    }
    "private-1" = {
      cidr_index = 10
      type       = "private"
      public_ip  = false
    }
    "private-2" = {
      cidr_index = 11
      type       = "private"
      public_ip  = false
    }
  }
}

resource "aws_subnet" "dynamic" {
  for_each = var.subnet_config

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value.cidr_index)
  availability_zone       = data.aws_availability_zones.available.names[each.value.cidr_index % 2]
  map_public_ip_on_launch = each.value.public_ip

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Type = each.value.type
  }
}

# ===========================================
# Example 8: CloudWatch Metric Alarms
# ===========================================

variable "cloudwatch_alarms" {
  description = "CloudWatch alarm configurations"
  type = list(object({
    name                = string
    metric_name         = string
    comparison_operator = string
    threshold           = number
    evaluation_periods  = number
    period              = number
    statistic           = string
    alarm_description   = string
  }))
  default = [
    {
      name                = "high-cpu"
      metric_name         = "CPUUtilization"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      period              = 300
      statistic           = "Average"
      alarm_description   = "CPU utilization is too high"
    },
    {
      name                = "high-memory"
      metric_name         = "MemoryUtilization"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 85
      evaluation_periods  = 2
      period              = 300
      statistic           = "Average"
      alarm_description   = "Memory utilization is too high"
    }
  ]
}

resource "aws_cloudwatch_metric_alarm" "ec2" {
  for_each = { for alarm in var.cloudwatch_alarms : alarm.name => alarm }

  alarm_name          = "${local.name_prefix}-${each.value.name}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = "AWS/EC2"
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description

  dimensions = {
    InstanceId = aws_instance.app.id
  }

  tags = {
    Name = "${local.name_prefix}-${each.value.name}-alarm"
  }
}

# ===========================================
# Outputs
# ===========================================

output "security_group_rules" {
  description = "All ingress rules applied to web security group"
  value = [
    for rule in local.all_ingress_rules : {
      ports       = "${rule.from_port}-${rule.to_port}"
      protocol    = rule.protocol
      cidr_blocks = rule.cidr_blocks
      description = rule.description
    }
  ]
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "ebs_volumes_attached" {
  description = "EBS volumes attached to instance"
  value = [
    for vol in var.ebs_volumes : {
      device = vol.device_name
      size   = vol.volume_size
      type   = vol.volume_type
    }
  ]
}

output "asg_tags" {
  description = "Tags applied to ASG"
  value       = var.asg_tags
}

output "iam_policy_json" {
  description = "Generated IAM policy document"
  value       = data.aws_iam_policy_document.app_policy.json
}

output "service_ports_configured" {
  description = "Service ports configured in security group"
  value       = { for k, v in var.service_ports : k => v.port }
}

output "subnets_created" {
  description = "Subnets created"
  value = {
    for k, v in aws_subnet.dynamic :
    k => {
      id         = v.id
      cidr_block = v.cidr_block
      az         = v.availability_zone
    }
  }
}
