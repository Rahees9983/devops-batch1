# Terraform Provisioners

## What are Provisioners?

Provisioners are used to execute scripts or commands on a local or remote machine as part of resource creation or destruction. They should be used as a **last resort** when no other option exists.

## Why "Last Resort"?

Provisioners:
- Break Terraform's declarative model
- Make configurations less predictable
- Can fail without proper error handling
- Don't appear in plan output
- Can't be fully modeled by Terraform

## Better Alternatives

| Use Case | Better Alternative |
|----------|-------------------|
| Configure VM | Pre-built AMI/image with Packer |
| Install software | Cloud-init, user_data |
| Run scripts | Configuration management (Ansible, Chef, Puppet) |
| Pass data to instances | User data, SSM Parameter Store, Secrets Manager |

---

## Types of Provisioners

### 1. local-exec

Runs commands on the machine running Terraform.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}
```

### 2. remote-exec

Runs commands on the remote resource.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }
}
```

### 3. file

Copies files to the remote resource.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "config/app.conf"
    destination = "/tmp/app.conf"
  }

  provisioner "file" {
    content     = "Hello, World!"
    destination = "/tmp/hello.txt"
  }
}
```

---

## Connection Block

Required for remote-exec and file provisioners.

### SSH Connection (Linux)

```hcl
connection {
  type        = "ssh"
  user        = "ec2-user"
  private_key = file("~/.ssh/id_rsa")
  host        = self.public_ip
  port        = 22
  timeout     = "5m"
}
```

### SSH with Bastion Host

```hcl
connection {
  type        = "ssh"
  user        = "ec2-user"
  private_key = file("~/.ssh/id_rsa")
  host        = self.private_ip

  bastion_host        = aws_instance.bastion.public_ip
  bastion_user        = "ec2-user"
  bastion_private_key = file("~/.ssh/bastion-key.pem")
}
```

### WinRM Connection (Windows)

```hcl
connection {
  type     = "winrm"
  user     = "Administrator"
  password = var.admin_password
  host     = self.public_ip
  port     = 5986
  https    = true
  insecure = true
  timeout  = "10m"
}
```

---

## Provisioner Timing

### on create (default)

Runs when the resource is created.

```hcl
provisioner "local-exec" {
  command = "echo 'Resource created'"
}
```

### on destroy

Runs when the resource is destroyed.

```hcl
provisioner "local-exec" {
  when    = destroy
  command = "echo 'Resource ${self.id} is being destroyed'"
}
```

---

## Error Handling

### on_failure = continue

Continue even if provisioner fails.

```hcl
provisioner "local-exec" {
  command    = "exit 1"
  on_failure = continue  # Don't fail the apply
}
```

### on_failure = fail (default)

Fail the apply if provisioner fails.

```hcl
provisioner "local-exec" {
  command    = "exit 1"
  on_failure = fail  # This is the default
}
```

---

## Detailed Examples

### Example 1: local-exec for API Calls

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server"
  }

  # Register with external service after creation
  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST https://api.example.com/register \
        -H "Content-Type: application/json" \
        -d '{"instance_id": "${self.id}", "ip": "${self.private_ip}"}'
    EOT
  }

  # Deregister on destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      curl -X DELETE https://api.example.com/deregister/${self.id}
    EOT

    on_failure = continue
  }
}
```

### Example 2: local-exec with Environment Variables

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "python3 scripts/configure.py"

    environment = {
      INSTANCE_ID = self.id
      PRIVATE_IP  = self.private_ip
      PUBLIC_IP   = self.public_ip
      REGION      = var.aws_region
    }
  }
}
```

### Example 3: local-exec with Interpreter

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # PowerShell on Windows
  provisioner "local-exec" {
    command     = "Write-Host 'Instance ID: ${self.id}'"
    interpreter = ["PowerShell", "-Command"]
  }

  # Python script
  provisioner "local-exec" {
    command     = "print('Instance created: ${self.id}')"
    interpreter = ["python3", "-c"]
  }
}
```

### Example 4: remote-exec with Script

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }

  # Copy script file
  provisioner "file" {
    source      = "scripts/setup.sh"
    destination = "/tmp/setup.sh"
  }

  # Execute the script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh"
    ]
  }
}
```

### Example 5: remote-exec with Scripts

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    scripts = [
      "scripts/install-packages.sh",
      "scripts/configure-app.sh",
      "scripts/start-services.sh"
    ]
  }
}
```

### Example 6: File Provisioner with Directory

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }

  # Copy entire directory
  provisioner "file" {
    source      = "config/"      # Note the trailing slash
    destination = "/opt/app/config"
  }

  # Copy directory (without trailing slash includes the directory itself)
  provisioner "file" {
    source      = "scripts"      # Copies as /opt/scripts/
    destination = "/opt"
  }
}
```

### Example 7: Multiple Provisioners

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }

  # Provisioners run in order
  provisioner "file" {
    source      = "config/app.conf"
    destination = "/tmp/app.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/app.conf /etc/app/app.conf",
      "sudo chown root:root /etc/app/app.conf"
    ]
  }

  provisioner "local-exec" {
    command = "echo 'Configuration complete for ${self.id}'"
  }
}
```

---

## null_resource with Provisioners

Use `null_resource` to run provisioners independently of other resources.

```hcl
resource "null_resource" "configure_app" {
  # Trigger when instance changes
  triggers = {
    instance_id = aws_instance.web.id
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo systemctl start docker"
    ]
  }

  depends_on = [aws_instance.web]
}
```

### Trigger on Every Apply

```hcl
resource "null_resource" "always_run" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'This runs every apply'"
  }
}
```

---

## Better Alternative: user_data

Instead of remote-exec, prefer cloud-init / user_data:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from $(hostname)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server"
  }
}
```

### user_data with templatefile

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  user_data = templatefile("${path.module}/scripts/user_data.sh.tpl", {
    db_host     = aws_db_instance.main.address
    db_name     = var.db_name
    environment = var.environment
  })
}
```

---

## Best Practices

1. **Avoid provisioners when possible** - Use user_data, pre-built images, or config management
2. **Keep provisioners simple** - Complex logic belongs elsewhere
3. **Handle errors gracefully** - Use on_failure appropriately
4. **Use null_resource** for provisioners not tied to specific resources
5. **Prefer local-exec over remote-exec** - Less network issues
6. **Test provisioners thoroughly** - They can fail silently
7. **Log provisioner output** - For debugging
8. **Consider idempotency** - Provisioners may run multiple times

---

## Lab Exercise

1. Create an EC2 instance with remote-exec to install Apache
2. Use file provisioner to copy a custom index.html
3. Add local-exec to log the instance IP
4. Create a null_resource with triggers
5. Refactor to use user_data instead of remote-exec
