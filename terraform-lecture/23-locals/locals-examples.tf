# ===========================================
# Additional Local Values Examples
# ===========================================

# This file contains more advanced examples of local values
# These demonstrate various patterns and use cases

# ===========================================
# Pattern 1: Configuration Objects
# ===========================================

locals {
  # Application configuration
  app_config = {
    name        = var.project_name
    version     = "1.0.0"
    port        = 8080
    health_path = "/health"
    log_level   = local.is_production ? "warn" : "debug"
  }

  # Database configuration
  db_config = {
    engine         = "postgres"
    engine_version = "14.7"
    instance_class = local.is_production ? "db.r5.large" : "db.t3.micro"
    allocated_storage = local.is_production ? 100 : 20
    multi_az       = local.is_production
    backup_retention_period = local.is_production ? 30 : 7
    deletion_protection = local.is_production
  }

  # Cache configuration
  cache_config = {
    engine         = "redis"
    engine_version = "7.0"
    node_type      = local.is_production ? "cache.r6g.large" : "cache.t3.micro"
    num_cache_nodes = local.is_production ? 3 : 1
  }
}

# ===========================================
# Pattern 2: Environment-Specific Maps
# ===========================================

locals {
  # Instance types per environment
  instance_type_map = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.large"
  }

  # Replica counts per environment
  replica_count_map = {
    dev     = 1
    staging = 2
    prod    = 3
  }

  # CIDR blocks per environment
  vpc_cidr_map = {
    dev     = "10.1.0.0/16"
    staging = "10.2.0.0/16"
    prod    = "10.0.0.0/16"
  }

  # Look up values based on environment
  selected_instance_type = lookup(local.instance_type_map, var.environment, "t3.micro")
  selected_replica_count = lookup(local.replica_count_map, var.environment, 1)
}

# ===========================================
# Pattern 3: String Manipulation
# ===========================================

locals {
  # Various string manipulations
  strings = {
    # Lowercase
    lowercase_name = lower(var.project_name)

    # Uppercase
    uppercase_env = upper(var.environment)

    # Replace characters
    sanitized_name = replace(var.project_name, "_", "-")

    # Remove special characters (keep only alphanumeric and hyphens)
    clean_name = replace(lower(var.project_name), "/[^a-z0-9-]/", "")

    # Truncate to max length (for resources with name limits)
    truncated_name = substr(var.project_name, 0, min(length(var.project_name), 20))

    # Title case
    title_name = title(var.project_name)

    # Split and join
    name_parts = split("-", var.project_name)
    joined_name = join("_", ["prefix", var.project_name, var.environment])

    # Format with padding
    padded_count = format("%03d", 1)  # "001"
  }
}

# ===========================================
# Pattern 4: Collection Transformations
# ===========================================

locals {
  # Sample data
  raw_instances = [
    { name = "web-1", type = "t3.micro", az = "a" },
    { name = "web-2", type = "t3.micro", az = "b" },
    { name = "api-1", type = "t3.small", az = "a" },
    { name = "worker-1", type = "t3.medium", az = "c" }
  ]

  # Transform list to map (for for_each)
  instances_map = {
    for inst in local.raw_instances :
    inst.name => inst
  }

  # Filter by type
  micro_instances = [
    for inst in local.raw_instances :
    inst
    if inst.type == "t3.micro"
  ]

  # Extract single attribute
  instance_names = [for inst in local.raw_instances : inst.name]

  # Group by availability zone
  instances_by_az = {
    for inst in local.raw_instances :
    inst.az => inst...
  }

  # Add computed fields
  enriched_instances = [
    for inst in local.raw_instances : merge(inst, {
      full_name = "${local.name_prefix}-${inst.name}"
      full_az   = "${var.aws_region}${inst.az}"
    })
  ]

  # Create index map
  instance_index = {
    for idx, inst in local.raw_instances :
    inst.name => idx
  }
}

# ===========================================
# Pattern 5: Nested Data Structures
# ===========================================

locals {
  # Multi-tier application configuration
  application_tiers = {
    frontend = {
      instances = 2
      instance_type = "t3.small"
      port = 80
      health_check = "/health"
      public = true
      security_groups = ["web", "monitoring"]
    }
    backend = {
      instances = 3
      instance_type = "t3.medium"
      port = 8080
      health_check = "/api/health"
      public = false
      security_groups = ["api", "monitoring"]
    }
    worker = {
      instances = 2
      instance_type = "t3.large"
      port = null
      health_check = null
      public = false
      security_groups = ["worker", "monitoring"]
    }
  }

  # Flatten for iteration
  all_tier_instances = flatten([
    for tier_name, tier_config in local.application_tiers : [
      for i in range(tier_config.instances) : {
        name          = "${tier_name}-${i + 1}"
        tier          = tier_name
        instance_type = tier_config.instance_type
        port          = tier_config.port
        public        = tier_config.public
      }
    ]
  ])
}

# ===========================================
# Pattern 6: Conditional Resources
# ===========================================

locals {
  # Determine which optional resources to create
  create_resources = {
    nat_gateway     = local.is_production || local.is_staging
    bastion_host    = !local.is_production  # Only in non-prod
    vpn_gateway     = local.is_production
    waf             = local.is_production
    cloudfront      = local.is_production
    backup_vault    = local.is_production || local.is_staging
    monitoring      = true  # Always create
    alerting        = local.is_production
  }

  # Resources that need the NAT Gateway
  needs_nat = local.create_resources.nat_gateway
}

# ===========================================
# Pattern 7: Dynamic Block Data
# ===========================================

locals {
  # EBS volumes configuration
  ebs_volumes = local.is_production ? [
    { device_name = "/dev/sdb", size = 100, type = "gp3" },
    { device_name = "/dev/sdc", size = 200, type = "gp3" },
  ] : [
    { device_name = "/dev/sdb", size = 20, type = "gp2" },
  ]

  # IAM policy statements
  iam_statements = [
    {
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::${local.bucket_names.data}/*"]
    },
    {
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["arn:aws:logs:*:*:*"]
    }
  ]
}

# ===========================================
# Pattern 8: Time-Based Values
# ===========================================

locals {
  timestamps = {
    # Current timestamp
    now = timestamp()

    # Formatted timestamps
    date_only = formatdate("YYYY-MM-DD", timestamp())
    time_only = formatdate("HH:mm:ss", timestamp())
    full      = formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp())

    # For naming (no special characters)
    for_naming = formatdate("YYYYMMDD-HHmmss", timestamp())
  }

  # Calculate future dates (for certificate expiry, etc.)
  # Note: This is calculated at plan time
  expiry_date = timeadd(timestamp(), "8760h")  # 1 year from now
}

# ===========================================
# Pattern 9: File-Based Configuration
# ===========================================

# Uncomment these if you have the corresponding files

# locals {
#   # Read JSON configuration
#   json_config = jsondecode(file("${path.module}/config.json"))
#
#   # Read YAML configuration
#   yaml_config = yamldecode(file("${path.module}/config.yaml"))
#
#   # Read and decode base64
#   decoded_secret = base64decode(file("${path.module}/secret.b64"))
#
#   # Template file
#   user_data = templatefile("${path.module}/scripts/user-data.sh", {
#     environment = var.environment
#     app_name    = var.project_name
#     region      = var.aws_region
#   })
# }

# ===========================================
# Pattern 10: Error Prevention / Validation
# ===========================================

locals {
  # Ensure valid values with coalesce
  safe_environment = coalesce(var.environment, "dev")

  # Provide defaults for potentially null values
  safe_project_name = var.project_name != null ? var.project_name : "unnamed"

  # Clamp values to valid range
  clamped_instance_count = min(max(local.instance_count, 1), 10)

  # Validate and transform
  validated_cidr = can(cidrhost(var.vpc_cidr, 0)) ? var.vpc_cidr : "10.0.0.0/16"
}
