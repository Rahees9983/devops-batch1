# Terraform Functions

## Overview

Terraform provides built-in functions for transforming and combining values. Functions can be used in expressions to compute values dynamically.

## Function Categories

1. **String Functions**
2. **Numeric Functions**
3. **Collection Functions**
4. **Encoding Functions**
5. **Filesystem Functions**
6. **Date and Time Functions**
7. **Type Conversion Functions**
8. **IP Network Functions**

---

## String Functions

### format

Format a string using printf-style syntax.

```hcl
# format(spec, values...)
format("Hello, %s!", "World")
# Result: "Hello, World!"

format("Instance %s has IP %s", "web-1", "10.0.1.5")
# Result: "Instance web-1 has IP 10.0.1.5"

format("%d instances running", 5)
# Result: "5 instances running"

# In resources
resource "aws_instance" "web" {
  tags = {
    Name = format("%s-%s-%02d", var.project, var.environment, count.index + 1)
    # Result: "myapp-prod-01"
  }
}
```

### join

Join list elements with a separator.

```hcl
# join(separator, list)
join(", ", ["a", "b", "c"])
# Result: "a, b, c"

join("-", ["web", "server", "01"])
# Result: "web-server-01"

# Join subnet IDs for output
output "subnet_ids" {
  value = join(",", aws_subnet.private[*].id)
}
```

### split

Split a string into a list.

```hcl
# split(separator, string)
split(",", "a,b,c")
# Result: ["a", "b", "c"]

split("/", "10.0.0.0/16")
# Result: ["10.0.0.0", "16"]
```

### lower / upper

Convert case.

```hcl
lower("HELLO")
# Result: "hello"

upper("hello")
# Result: "HELLO"

# Normalize environment name
locals {
  environment = lower(var.environment)
}
```

### replace

Replace substring.

```hcl
# replace(string, substring, replacement)
replace("hello world", "world", "terraform")
# Result: "hello terraform"

# Remove characters
replace("my-bucket-name", "-", "")
# Result: "mybucketname"
```

### trim / trimprefix / trimsuffix

Remove characters from strings.

```hcl
trim("  hello  ", " ")
# Result: "hello"

trimprefix("helloworld", "hello")
# Result: "world"

trimsuffix("helloworld", "world")
# Result: "hello"
```

### substr

Extract substring.

```hcl
# substr(string, offset, length)
substr("hello world", 0, 5)
# Result: "hello"

substr("hello world", 6, -1)  # -1 means to end
# Result: "world"
```

### regex / regexall

Regular expression matching.

```hcl
# regex(pattern, string)
regex("[a-z]+", "123abc456")
# Result: "abc"

regexall("[a-z]+", "abc123def456")
# Result: ["abc", "def"]

# Extract version number
regex("v([0-9]+)\\.([0-9]+)", "v1.2")
# Result: ["1", "2"]
```

---

## Numeric Functions

### abs / ceil / floor

```hcl
abs(-5)
# Result: 5

ceil(4.3)
# Result: 5

floor(4.9)
# Result: 4
```

### max / min

```hcl
max(1, 5, 3)
# Result: 5

min(1, 5, 3)
# Result: 1

max(aws_instance.web[*].cpu_credits...)
```

### parseint

```hcl
parseint("100", 10)
# Result: 100

parseint("FF", 16)
# Result: 255
```

---

## Collection Functions

### length

Get collection size.

```hcl
length(["a", "b", "c"])
# Result: 3

length({a = 1, b = 2})
# Result: 2

length("hello")
# Result: 5

# Dynamic count
resource "aws_instance" "web" {
  count = length(var.availability_zones)
}
```

### element

Get element by index (wraps around).

```hcl
# element(list, index)
element(["a", "b", "c"], 0)
# Result: "a"

element(["a", "b", "c"], 3)
# Result: "a" (wraps around)

# Distribute across AZs
resource "aws_instance" "web" {
  count             = 5
  availability_zone = element(var.azs, count.index)
}
```

### lookup

Get value from map with default.

```hcl
# lookup(map, key, default)
lookup({a = 1, b = 2}, "a", 0)
# Result: 1

lookup({a = 1, b = 2}, "c", 0)
# Result: 0 (default)

# Instance type per environment
locals {
  instance_types = {
    dev  = "t2.micro"
    prod = "t2.large"
  }
}

resource "aws_instance" "web" {
  instance_type = lookup(local.instance_types, var.environment, "t2.small")
}
```

### concat

Combine lists.

```hcl
concat(["a", "b"], ["c", "d"])
# Result: ["a", "b", "c", "d"]

concat(var.public_subnets, var.private_subnets)
```

### merge

Combine maps.

```hcl
merge({a = 1}, {b = 2}, {c = 3})
# Result: {a = 1, b = 2, c = 3}

# Merge tags
resource "aws_instance" "web" {
  tags = merge(var.common_tags, {
    Name = "web-server"
    Role = "application"
  })
}
```

### flatten

Flatten nested lists.

```hcl
flatten([["a", "b"], ["c", "d"]])
# Result: ["a", "b", "c", "d"]

# Flatten subnet IDs from multiple VPCs
locals {
  all_subnets = flatten([
    module.vpc_a.subnet_ids,
    module.vpc_b.subnet_ids
  ])
}
```

### distinct

Remove duplicates.

```hcl
distinct(["a", "b", "a", "c", "b"])
# Result: ["a", "b", "c"]
```

### contains

Check if list contains value.

```hcl
contains(["a", "b", "c"], "b")
# Result: true

contains(["a", "b", "c"], "d")
# Result: false

# Validation
variable "environment" {
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}
```

### keys / values

Get keys or values from map.

```hcl
keys({a = 1, b = 2, c = 3})
# Result: ["a", "b", "c"]

values({a = 1, b = 2, c = 3})
# Result: [1, 2, 3]
```

### zipmap

Create map from two lists.

```hcl
zipmap(["a", "b", "c"], [1, 2, 3])
# Result: {a = 1, b = 2, c = 3}

# Create instance name to ID map
locals {
  instance_map = zipmap(
    aws_instance.web[*].tags.Name,
    aws_instance.web[*].id
  )
}
```

### range

Generate sequence of numbers.

```hcl
range(5)
# Result: [0, 1, 2, 3, 4]

range(1, 5)
# Result: [1, 2, 3, 4]

range(0, 10, 2)
# Result: [0, 2, 4, 6, 8]
```

### slice

Extract portion of list.

```hcl
# slice(list, start, end)
slice(["a", "b", "c", "d"], 1, 3)
# Result: ["b", "c"]
```

### sort / reverse

```hcl
sort(["c", "a", "b"])
# Result: ["a", "b", "c"]

reverse(["a", "b", "c"])
# Result: ["c", "b", "a"]
```

### coalesce / coalescelist

Return first non-null/non-empty value.

```hcl
coalesce("", "default")
# Result: "default"

coalesce(var.custom_name, "${var.project}-default")

coalescelist(var.custom_list, ["default"])
```

---

## Encoding Functions

### jsonencode / jsondecode

```hcl
jsonencode({name = "web", port = 80})
# Result: "{\"name\":\"web\",\"port\":80}"

jsondecode("{\"name\":\"web\",\"port\":80}")
# Result: {name = "web", port = 80}

# IAM policy
resource "aws_iam_policy" "example" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["*"]
    }]
  })
}
```

### base64encode / base64decode

```hcl
base64encode("Hello, World!")
# Result: "SGVsbG8sIFdvcmxkIQ=="

base64decode("SGVsbG8sIFdvcmxkIQ==")
# Result: "Hello, World!"

# User data
resource "aws_instance" "web" {
  user_data = base64encode(templatefile("user_data.sh", {
    db_host = var.db_host
  }))
}
```

### yamlencode / yamldecode

```hcl
yamlencode({name = "web", ports = [80, 443]})
# Result: "name: web\nports:\n- 80\n- 443\n"

yamldecode("name: web\nport: 80")
# Result: {name = "web", port = 80}
```

---

## Filesystem Functions

### file

Read file contents.

```hcl
file("${path.module}/scripts/setup.sh")

resource "aws_instance" "web" {
  user_data = file("${path.module}/user_data.sh")
}
```

### fileexists

Check if file exists.

```hcl
fileexists("${path.module}/custom.conf")
# Result: true or false

locals {
  config = fileexists("${path.module}/custom.conf") ? file("${path.module}/custom.conf") : ""
}
```

### templatefile

Render template with variables.

```hcl
# templates/user_data.sh.tpl
#!/bin/bash
export DB_HOST=${db_host}
export DB_NAME=${db_name}
export ENVIRONMENT=${environment}
/opt/app/start.sh

# main.tf
resource "aws_instance" "web" {
  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    db_host     = aws_db_instance.main.address
    db_name     = var.db_name
    environment = var.environment
  })
}
```

### dirname / basename

```hcl
dirname("/path/to/file.txt")
# Result: "/path/to"

basename("/path/to/file.txt")
# Result: "file.txt"
```

### pathexpand

Expand ~ to home directory.

```hcl
pathexpand("~/.ssh/id_rsa")
# Result: "/home/user/.ssh/id_rsa"
```

---

## Date and Time Functions

### timestamp

Current timestamp.

```hcl
timestamp()
# Result: "2024-01-15T10:30:00Z"

resource "aws_instance" "web" {
  tags = {
    CreatedAt = timestamp()
  }
}
```

### formatdate

Format a timestamp.

```hcl
formatdate("YYYY-MM-DD", timestamp())
# Result: "2024-01-15"

formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
# Result: "15 Jan 2024 10:30 UTC"
```

### timeadd

Add duration to timestamp.

```hcl
timeadd(timestamp(), "24h")
# Result: timestamp + 24 hours

timeadd("2024-01-15T00:00:00Z", "168h")
# Result: "2024-01-22T00:00:00Z" (one week later)
```

---

## Type Conversion Functions

### tostring / tonumber / tobool

```hcl
tostring(123)
# Result: "123"

tonumber("123")
# Result: 123

tobool("true")
# Result: true
```

### tolist / toset / tomap

```hcl
tolist(["a", "b", "c"])
# Ensures list type

toset(["a", "b", "a"])
# Result: toset(["a", "b"])

tomap({a = 1, b = 2})
# Ensures map type
```

### try

Return first successful expression.

```hcl
try(var.optional_value, "default")

try(
  jsondecode(var.json_string).key,
  "fallback"
)

# Safe nested access
try(var.config.database.host, "localhost")
```

### can

Test if expression is valid.

```hcl
can(regex("^ami-", var.ami_id))
# Result: true or false

variable "cidr" {
  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "Must be valid CIDR."
  }
}
```

---

## IP Network Functions

### cidrhost

Get host address in CIDR.

```hcl
cidrhost("10.0.0.0/24", 5)
# Result: "10.0.0.5"
```

### cidrnetmask

Get netmask from CIDR.

```hcl
cidrnetmask("10.0.0.0/16")
# Result: "255.255.0.0"
```

### cidrsubnet

Calculate subnet CIDR.

```hcl
# cidrsubnet(prefix, newbits, netnum)
cidrsubnet("10.0.0.0/16", 8, 1)
# Result: "10.0.1.0/24"

cidrsubnet("10.0.0.0/16", 8, 2)
# Result: "10.0.2.0/24"

# Dynamic subnet creation
resource "aws_subnet" "private" {
  count      = 3
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
}
```

---

## Practical Examples

### Example 1: Dynamic Tags

```hcl
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }
}

resource "aws_instance" "web" {
  tags = merge(local.common_tags, {
    Name = format("%s-%s-web-%02d", var.project, var.environment, count.index + 1)
  })
}
```

### Example 2: Conditional Configuration

```hcl
locals {
  instance_type = lookup({
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.large"
  }, var.environment, "t2.micro")

  enable_monitoring = contains(["staging", "prod"], var.environment)
}
```

### Example 3: Complex Subnet Calculation

```hcl
locals {
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  subnets = flatten([
    for i, az in local.azs : [
      {
        name = "public-${az}"
        cidr = cidrsubnet(var.vpc_cidr, 8, i)
        az   = az
        type = "public"
      },
      {
        name = "private-${az}"
        cidr = cidrsubnet(var.vpc_cidr, 8, i + length(local.azs))
        az   = az
        type = "private"
      }
    ]
  ])
}
```

---

## Testing Functions

Use `terraform console` to test functions:

```bash
$ terraform console

> format("Hello %s", "World")
"Hello World"

> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"

> merge({a=1}, {b=2})
{
  "a" = 1
  "b" = 2
}

> exit
```

---

## Lab Exercise

1. Use `format` and `join` to create dynamic resource names
2. Use `lookup` to select values based on environment
3. Use `cidrsubnet` to calculate subnet CIDRs dynamically
4. Use `templatefile` to render a user_data script
5. Use `merge` to combine common and resource-specific tags
