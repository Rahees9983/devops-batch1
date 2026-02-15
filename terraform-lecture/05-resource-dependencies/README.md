# Terraform Resource Dependencies

## What are Resource Dependencies?

Resource dependencies define the order in which Terraform creates, updates, or destroys resources. Terraform uses dependencies to build a dependency graph and determine the correct order of operations.

## Types of Dependencies

1. **Implicit Dependencies**: Automatically created when you reference resource attributes
2. **Explicit Dependencies**: Manually specified using `depends_on`

## Implicit Dependencies

When you reference an attribute from one resource in another, Terraform automatically understands the dependency.

### Example: VPC and Subnet

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Implicit dependency on aws_vpc.main
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id    # <-- This creates an implicit dependency
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet"
  }
}
```

Terraform knows to:
1. Create the VPC first
2. Then create the subnet (because it needs the VPC ID)

### Example: Full Stack with Implicit Dependencies

```hcl
# 1. VPC is created first (no dependencies)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# 2. Internet Gateway depends on VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Implicit dependency on VPC
}

# 3. Subnet depends on VPC
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency on VPC
  cidr_block = "10.0.1.0/24"
}

# 4. Route Table depends on VPC and IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # Implicit dependency on IGW
  }
}

# 5. Route Table Association depends on Subnet and Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id       # Implicit dependency on Subnet
  route_table_id = aws_route_table.public.id  # Implicit dependency on Route Table
}

# 6. Security Group depends on VPC
resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id  # Implicit dependency on VPC

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
}

# 7. EC2 Instance depends on Subnet and Security Group
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id              # Implicit
  vpc_security_group_ids = [aws_security_group.web.id]       # Implicit

  tags = {
    Name = "web-server"
  }
}
```

## Explicit Dependencies (depends_on)

Use `depends_on` when there's a dependency that Terraform can't automatically detect.

### Syntax

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  depends_on = [
    aws_iam_role_policy.example,
    aws_s3_bucket.example
  ]
}
```

### When to Use depends_on

1. **IAM Policy Dependencies**: Instance needs IAM role but doesn't reference it directly
2. **Database Migrations**: Application needs database schema but doesn't reference migration resource
3. **External Dependencies**: When a resource depends on something not referenced in its arguments

### Example: IAM Role Dependency

```hcl
# IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# IAM Role Policy
resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = ["${aws_s3_bucket.app.arn}/*"]
    }]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# S3 Bucket
resource "aws_s3_bucket" "app" {
  bucket = "my-app-bucket-12345"
}

# EC2 Instance - needs explicit depends_on for policy
resource "aws_instance" "app" {
  ami                  = "ami-0c55b159cbfafe1f0"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # The instance might launch before the policy is attached
  # Use depends_on to ensure policy is ready
  depends_on = [aws_iam_role_policy.s3_access]

  tags = {
    Name = "app-server"
  }
}
```

### Example: Application depends on Database

```hcl
resource "aws_db_instance" "main" {
  identifier        = "mydb"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "myapp"
  username          = "admin"
  password          = var.db_password
  skip_final_snapshot = true
}

# Null resource to run database migrations
resource "null_resource" "db_migration" {
  depends_on = [aws_db_instance.main]

  provisioner "local-exec" {
    command = "mysql -h ${aws_db_instance.main.address} -u admin -p${var.db_password} < schema.sql"
  }
}

# Application instance needs migrations to complete
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # Explicit dependency on migrations
  depends_on = [null_resource.db_migration]

  user_data = <<-EOF
              #!/bin/bash
              export DB_HOST=${aws_db_instance.main.address}
              /opt/app/start.sh
              EOF

  tags = {
    Name = "app-server"
  }
}
```

## Viewing the Dependency Graph

```bash
# Generate a dependency graph in DOT format
terraform graph

# Generate and visualize (requires graphviz)
terraform graph | dot -Tpng > graph.png

# Generate graph for a specific plan
terraform graph -plan=tfplan
```

## Dependency Order

### Creation Order
Resources are created from leaves to root of the dependency tree:
1. Resources with no dependencies first
2. Then resources that depend on those
3. Continue until all resources are created

### Destruction Order
Resources are destroyed in reverse order:
1. Resources that nothing depends on first
2. Then their dependencies
3. Continue until all resources are destroyed

## Circular Dependencies

Terraform will error if it detects circular dependencies:

```hcl
# This will FAIL - circular dependency!
resource "aws_security_group" "a" {
  name = "sg-a"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.b.id]  # Depends on B
  }
}

resource "aws_security_group" "b" {
  name = "sg-b"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.a.id]  # Depends on A - CIRCULAR!
  }
}
```

### Solution: Use Security Group Rules

```hcl
resource "aws_security_group" "a" {
  name = "sg-a"
}

resource "aws_security_group" "b" {
  name = "sg-b"
}

# Separate rules avoid circular dependency
resource "aws_security_group_rule" "a_from_b" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.a.id
  source_security_group_id = aws_security_group.b.id
}

resource "aws_security_group_rule" "b_from_a" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.b.id
  source_security_group_id = aws_security_group.a.id
}
```

## Module Dependencies

```hcl
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "database" {
  source    = "./modules/database"
  vpc_id    = module.vpc.vpc_id       # Implicit dependency on VPC module
  subnet_ids = module.vpc.private_subnet_ids
}

module "application" {
  source     = "./modules/application"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  db_host    = module.database.endpoint  # Implicit dependency on database module

  # Explicit dependency if needed
  depends_on = [module.database]
}
```

## Best Practices

1. **Prefer implicit dependencies** when possible - they're clearer and self-documenting
2. **Use depends_on sparingly** - only when there's no attribute reference
3. **Avoid circular dependencies** by separating resources
4. **Document explicit dependencies** with comments explaining why they're needed
5. **Use terraform graph** to visualize and verify dependencies

## Lab Exercise

Create a Terraform configuration with:
1. A VPC with public and private subnets
2. An RDS instance in private subnets
3. An EC2 instance in public subnet that depends on RDS
4. Use both implicit and explicit dependencies appropriately
