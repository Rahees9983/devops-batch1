# ===========================================
# Provisioners - Complete Examples
# ===========================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  default = "demo"
}

variable "ssh_key_name" {
  description = "Name of SSH key pair"
  default     = "my-key"
}

variable "private_key_path" {
  description = "Path to private key file"
  default     = "~/.ssh/id_rsa"
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
# local-exec Provisioner
# Runs commands on the machine running Terraform
# ===========================================

resource "aws_instance" "local_exec_demo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "${var.environment}-local-exec"
  }

  # Run after instance is created
  provisioner "local-exec" {
    command = "echo 'Instance ${self.id} created with IP ${self.private_ip}' >> instances.txt"
  }

  # Run with environment variables
  provisioner "local-exec" {
    command = "python3 scripts/register.py"

    environment = {
      INSTANCE_ID = self.id
      PRIVATE_IP  = self.private_ip
      ENVIRONMENT = var.environment
    }

    on_failure = continue  # Don't fail if script doesn't exist
  }

  # Run on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance ${self.id} is being destroyed' >> destroyed.txt"

    on_failure = continue
  }
}

# ===========================================
# remote-exec Provisioner
# Runs commands on the remote resource
# ===========================================

resource "aws_security_group" "ssh" {
  name        = "${var.environment}-ssh-sg"
  description = "Allow SSH"

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

  tags = {
    Name = "${var.environment}-ssh-sg"
  }
}

resource "aws_instance" "remote_exec_demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "${var.environment}-remote-exec"
  }

  # Connection block for remote provisioners
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    timeout     = "5m"
  }

  # Inline commands
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "echo '<h1>Hello from ${self.id}</h1>' | sudo tee /var/www/html/index.html"
    ]
  }
}

# ===========================================
# file Provisioner
# Copies files to remote resource
# ===========================================

resource "aws_instance" "file_demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "${var.environment}-file-demo"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    timeout     = "5m"
  }

  # Copy a single file
  provisioner "file" {
    content     = "Hello from Terraform!"
    destination = "/tmp/hello.txt"
  }

  # Copy a local file
  # provisioner "file" {
  #   source      = "config/app.conf"
  #   destination = "/tmp/app.conf"
  # }

  # Copy a directory
  # provisioner "file" {
  #   source      = "scripts/"          # trailing slash = contents only
  #   destination = "/opt/scripts"
  # }

  # Make it executable and run
  provisioner "remote-exec" {
    inline = [
      "cat /tmp/hello.txt"
    ]
  }
}

# ===========================================
# null_resource with Provisioners
# Run provisioners independently of resources
# ===========================================

resource "null_resource" "configure_app" {
  # Trigger when instance changes
  triggers = {
    instance_id = aws_instance.local_exec_demo.id
    # always_run  = timestamp()  # Uncomment to run every apply
  }

  provisioner "local-exec" {
    command = "echo 'Configuring application for instance ${aws_instance.local_exec_demo.id}'"
  }
}

# ===========================================
# null_resource - Always Run
# ===========================================

resource "null_resource" "always_run" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'This runs on every terraform apply: ${timestamp()}'"
  }
}

# ===========================================
# BETTER ALTERNATIVE: user_data
# Preferred over provisioners for EC2
# ===========================================

resource "aws_instance" "user_data_demo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from user_data</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.environment}-user-data"
  }
}

# user_data with templatefile (even better)
resource "aws_instance" "user_data_template" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    environment = var.environment
    app_name    = "myapp"
  })

  tags = {
    Name = "${var.environment}-user-data-template"
  }
}

# Create template directory and file
resource "local_file" "user_data_template" {
  filename = "${path.module}/templates/user_data.sh.tpl"
  content  = <<-EOF
    #!/bin/bash
    echo "Environment: ${environment}"
    echo "App: ${app_name}"
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    cat > /var/www/html/index.html <<'HTMLEOF'
    <h1>Welcome to ${app_name}</h1>
    <p>Environment: ${environment}</p>
    HTMLEOF
  EOF
}

# ===========================================
# Outputs
# ===========================================

output "local_exec_instance_id" {
  value = aws_instance.local_exec_demo.id
}

output "remote_exec_public_ip" {
  value = aws_instance.remote_exec_demo.public_ip
}

output "user_data_instance_id" {
  value = aws_instance.user_data_demo.id
}

output "provisioner_info" {
  value = <<-EOT

    PROVISIONER TYPES:
    ==================

    1. local-exec: Runs on Terraform machine
       - API calls
       - Local file operations
       - Triggering external tools

    2. remote-exec: Runs on remote resource
       - inline: list of commands
       - script: single script file
       - scripts: multiple script files

    3. file: Copies files to remote
       - source + destination (file)
       - content + destination (inline)
       - source/ (directory)

    WHEN TO USE:
    ============
    - Provisioners are LAST RESORT
    - Prefer: user_data, AMI, config management

    ALTERNATIVES:
    =============
    - user_data for EC2 bootstrap
    - Packer for AMI building
    - Ansible/Chef/Puppet for config
    - AWS SSM for remote execution

  EOT
}
