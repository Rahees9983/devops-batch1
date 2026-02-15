# ===========================================
# Terraform Functions - Complete Examples
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

variable "project" {
  default = "myapp"
}

# ===========================================
# STRING FUNCTIONS
# ===========================================

locals {
  # format - Printf style formatting
  instance_name = format("%s-%s-web-%02d", var.project, var.environment, 1)
  # Result: "myapp-demo-web-01"

  # join - Join list elements
  subnet_list = join(", ", ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"])
  # Result: "10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24"

  # split - Split string into list
  cidr_parts = split("/", "10.0.0.0/16")
  # Result: ["10.0.0.0", "16"]

  # lower / upper - Case conversion
  env_lower = lower("PRODUCTION")
  env_upper = upper("development")

  # replace - String replacement
  bucket_name = replace("my-bucket-name", "-", "_")
  # Result: "my_bucket_name"

  # trim / trimprefix / trimsuffix
  trimmed     = trim("  hello  ", " ")
  no_prefix   = trimprefix("v1.0.0", "v")
  no_suffix   = trimsuffix("instance.tf", ".tf")

  # substr - Substring
  short_name = substr("very-long-name-here", 0, 10)
  # Result: "very-long-"

  # regex / regexall
  version_parts = regex("v([0-9]+)\\.([0-9]+)\\.([0-9]+)", "v1.2.3")
  # Result: ["1", "2", "3"]
}

# ===========================================
# NUMERIC FUNCTIONS
# ===========================================

locals {
  # abs / ceil / floor
  absolute = abs(-5)     # 5
  ceiling  = ceil(4.3)   # 5
  floored  = floor(4.9)  # 4

  # max / min
  maximum = max(1, 5, 3)  # 5
  minimum = min(1, 5, 3)  # 1

  # parseint
  decimal = parseint("100", 10)  # 100
  hex     = parseint("FF", 16)   # 255
}

# ===========================================
# COLLECTION FUNCTIONS
# ===========================================

variable "servers" {
  default = {
    web = { type = "t2.micro", count = 2 }
    app = { type = "t2.small", count = 3 }
    db  = { type = "t2.medium", count = 1 }
  }
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

locals {
  # length - Get collection size
  az_count = length(var.availability_zones)  # 3

  # element - Get element by index (wraps around)
  first_az = element(var.availability_zones, 0)  # "us-east-1a"
  wrap_az  = element(var.availability_zones, 5)  # "us-east-1c" (wraps)

  # lookup - Get value from map with default
  web_type = lookup(var.servers, "web", { type = "t2.nano", count = 1 }).type

  # concat - Combine lists
  all_cidrs = concat(["10.0.1.0/24"], ["10.0.2.0/24"])
  # Result: ["10.0.1.0/24", "10.0.2.0/24"]

  # merge - Combine maps
  merged_tags = merge(
    { Environment = var.environment },
    { Project = var.project },
    { ManagedBy = "terraform" }
  )

  # flatten - Flatten nested lists
  flat_list = flatten([["a", "b"], ["c", "d"]])
  # Result: ["a", "b", "c", "d"]

  # distinct - Remove duplicates
  unique_items = distinct(["a", "b", "a", "c", "b"])
  # Result: ["a", "b", "c"]

  # contains - Check if list contains value
  has_web = contains(keys(var.servers), "web")  # true

  # keys / values - Get map keys or values
  server_names = keys(var.servers)    # ["web", "app", "db"]
  server_configs = values(var.servers)

  # zipmap - Create map from two lists
  name_to_az = zipmap(
    ["server1", "server2", "server3"],
    var.availability_zones
  )
  # Result: {server1 = "us-east-1a", server2 = "us-east-1b", server3 = "us-east-1c"}

  # range - Generate sequence
  numbers = range(5)       # [0, 1, 2, 3, 4]
  evens   = range(0, 10, 2) # [0, 2, 4, 6, 8]

  # slice - Extract portion of list
  subset = slice(var.availability_zones, 0, 2)
  # Result: ["us-east-1a", "us-east-1b"]

  # sort / reverse
  sorted   = sort(["c", "a", "b"])     # ["a", "b", "c"]
  reversed = reverse(["a", "b", "c"])  # ["c", "b", "a"]

  # coalesce - First non-null/non-empty value
  default_name = coalesce("", "default-name")  # "default-name"
}

# ===========================================
# ENCODING FUNCTIONS
# ===========================================

locals {
  # jsonencode / jsondecode
  json_string = jsonencode({
    name = "web-server"
    port = 80
    tags = ["http", "web"]
  })

  json_object = jsondecode("{\"name\":\"app\",\"port\":8080}")

  # base64encode / base64decode
  encoded = base64encode("Hello, World!")
  decoded = base64decode("SGVsbG8sIFdvcmxkIQ==")

  # yamlencode
  yaml_string = yamlencode({
    servers = ["web", "app", "db"]
    config = {
      port = 8080
    }
  })
}

# ===========================================
# FILESYSTEM FUNCTIONS
# ===========================================

locals {
  # file - Read file contents
  # user_data = file("${path.module}/scripts/user_data.sh")

  # fileexists - Check if file exists
  # has_config = fileexists("${path.module}/config.json")

  # templatefile - Render template
  # rendered = templatefile("${path.module}/templates/config.tpl", {
  #   environment = var.environment
  #   port        = 8080
  # })

  # dirname / basename
  dir  = dirname("/path/to/file.txt")   # "/path/to"
  base = basename("/path/to/file.txt")  # "file.txt"

  # pathexpand
  expanded = pathexpand("~/.ssh/id_rsa")  # "/home/user/.ssh/id_rsa"
}

# ===========================================
# DATE AND TIME FUNCTIONS
# ===========================================

locals {
  # timestamp - Current time
  current_time = timestamp()

  # formatdate - Format timestamp
  date_formatted = formatdate("YYYY-MM-DD", timestamp())
  time_formatted = formatdate("hh:mm:ss", timestamp())
  full_formatted = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())

  # timeadd - Add duration to timestamp
  future_time = timeadd(timestamp(), "24h")
  week_later  = timeadd(timestamp(), "168h")
}

# ===========================================
# TYPE CONVERSION FUNCTIONS
# ===========================================

locals {
  # tostring / tonumber / tobool
  str_value  = tostring(123)     # "123"
  num_value  = tonumber("456")   # 456
  bool_value = tobool("true")    # true

  # tolist / toset / tomap
  list_value = tolist(["a", "b", "c"])
  set_value  = toset(["a", "b", "a"])  # toset(["a", "b"])
  map_value  = tomap({ a = 1, b = 2 })

  # try - Return first successful expression
  safe_value = try(var.servers["web"].type, "t2.micro")

  # can - Test if expression is valid
  is_valid = can(regex("^[a-z]+$", "hello"))  # true
}

# ===========================================
# IP NETWORK FUNCTIONS
# ===========================================

locals {
  # cidrhost - Get host address in CIDR
  host_ip = cidrhost("10.0.0.0/24", 5)  # "10.0.0.5"

  # cidrnetmask - Get netmask
  netmask = cidrnetmask("10.0.0.0/16")  # "255.255.0.0"

  # cidrsubnet - Calculate subnet CIDR
  subnet1 = cidrsubnet("10.0.0.0/16", 8, 1)  # "10.0.1.0/24"
  subnet2 = cidrsubnet("10.0.0.0/16", 8, 2)  # "10.0.2.0/24"
  subnet3 = cidrsubnet("10.0.0.0/16", 8, 10) # "10.0.10.0/24"
}

# ===========================================
# Practical Examples
# ===========================================

data "aws_availability_zones" "available" {
  state = "available"
}

# Dynamic subnet calculation
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = local.merged_tags
}

resource "aws_subnet" "public" {
  count = min(length(data.aws_availability_zones.available.names), 3)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.merged_tags, {
    Name = format("%s-%s-public-%02d", var.project, var.environment, count.index + 1)
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# ===========================================
# Outputs
# ===========================================

output "string_examples" {
  value = {
    instance_name = local.instance_name
    subnet_list   = local.subnet_list
    cidr_parts    = local.cidr_parts
    no_prefix     = local.no_prefix
  }
}

output "collection_examples" {
  value = {
    az_count    = local.az_count
    merged_tags = local.merged_tags
    name_to_az  = local.name_to_az
    unique      = local.unique_items
  }
}

output "network_examples" {
  value = {
    host_ip = local.host_ip
    subnet1 = local.subnet1
    subnet2 = local.subnet2
    netmask = local.netmask
  }
}

output "date_examples" {
  value = {
    date_formatted = local.date_formatted
    full_formatted = local.full_formatted
  }
}

output "created_subnets" {
  value = {
    for idx, subnet in aws_subnet.public :
    format("subnet-%d", idx + 1) => {
      id         = subnet.id
      cidr_block = subnet.cidr_block
      az         = subnet.availability_zone
    }
  }
}
