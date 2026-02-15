# Terraform Taints

## What is Taint?

Tainting marks a resource for recreation on the next apply. When a resource is tainted, Terraform will destroy and recreate it even if its configuration hasn't changed.

## Important Note: Deprecation

The `terraform taint` command is **deprecated** since Terraform v0.15.2. Use the `-replace` flag instead:

```bash
# Old way (deprecated)
terraform taint aws_instance.web

# New way (recommended)
terraform apply -replace="aws_instance.web"
```

---

## Using -replace (Recommended)

### Basic Usage

```bash
# Mark resource for replacement and apply
terraform apply -replace="aws_instance.web"

# Replace multiple resources
terraform apply \
  -replace="aws_instance.web" \
  -replace="aws_instance.app"

# Preview replacement first
terraform plan -replace="aws_instance.web"
```

### Example Output

```bash
$ terraform plan -replace="aws_instance.web"

Terraform will perform the following actions:

  # aws_instance.web will be replaced, as requested
-/+ resource "aws_instance" "web" {
      ~ arn                    = "arn:aws:ec2:us-east-1:123456:instance/i-abc123" -> (known after apply)
      ~ id                     = "i-abc123" -> (known after apply)
        instance_type          = "t2.micro"
        # (other attributes unchanged)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

---

## Legacy taint Command (Deprecated)

### terraform taint

```bash
# Taint a resource
terraform taint aws_instance.web

# Output:
# Resource instance aws_instance.web has been marked as tainted.

# Taint resource in a module
terraform taint module.webserver.aws_instance.web

# Taint indexed resource
terraform taint 'aws_instance.web[0]'

# Taint for_each resource
terraform taint 'aws_instance.server["web"]'
```

### terraform untaint

Remove taint from a resource:

```bash
# Untaint a resource
terraform untaint aws_instance.web

# Output:
# Resource instance aws_instance.web has been successfully untainted.
```

---

## When to Use Replacement

### 1. Corrupted Resource

When a resource is in a bad state but Terraform thinks it's healthy:

```bash
# Instance is stuck or corrupted
terraform apply -replace="aws_instance.web"
```

### 2. Force Update

When you need to recreate a resource without configuration changes:

```bash
# Refresh instance with latest AMI (assuming AMI ID changed outside TF)
terraform apply -replace="aws_instance.web"
```

### 3. Testing Recreations

Test what happens when a resource is recreated:

```bash
# Preview the recreation
terraform plan -replace="aws_instance.web"
```

### 4. Rolling Updates

Manually trigger instance replacement in a cluster:

```bash
# Replace instances one at a time
terraform apply -replace="aws_instance.web[0]"
terraform apply -replace="aws_instance.web[1]"
terraform apply -replace="aws_instance.web[2]"
```

### 5. Provisioner Re-execution

When you need provisioners to run again:

```bash
# Force recreate to run provisioners
terraform apply -replace="aws_instance.web"
```

---

## How Taint/Replace Works

### State Representation

When a resource is tainted, its state includes a `status` field:

```json
{
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "status": "tainted",
          "attributes": {
            "id": "i-abc123"
          }
        }
      ]
    }
  ]
}
```

### Plan Behavior

Tainted resources show as "replace" in plans:

```
# aws_instance.web is tainted, so must be replaced
-/+ resource "aws_instance" "web" {
```

---

## Practical Examples

### Example 1: Replace Unhealthy Instance

```bash
# Instance is running but application won't start
# Check current state
terraform state show aws_instance.web

# Replace the instance
terraform apply -replace="aws_instance.web"
```

### Example 2: Replace After Manual Changes

```bash
# Someone made manual changes via console
# Force recreation to restore known state
terraform apply -replace="aws_instance.web" -auto-approve
```

### Example 3: Replace in Module

```bash
# Replace resource inside a module
terraform apply -replace="module.vpc.aws_subnet.private[0]"

# Replace multiple module resources
terraform apply \
  -replace="module.app.aws_instance.server" \
  -replace="module.app.aws_security_group.app"
```

### Example 4: Scripted Rolling Replacement

```bash
#!/bin/bash
# rolling-replace.sh

INSTANCES=$(terraform state list | grep 'aws_instance.web\[')

for instance in $INSTANCES; do
  echo "Replacing $instance..."
  terraform apply -replace="$instance" -auto-approve

  echo "Waiting for health check..."
  sleep 60

  echo "Completed $instance"
done
```

### Example 5: Replace with create_before_destroy

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}
```

```bash
# New instance created before old one destroyed
terraform apply -replace="aws_instance.web"

# Plan shows:
# +/- resource "aws_instance" "web" (create before destroy)
```

---

## Taint vs Other Methods

| Method | Use Case |
|--------|----------|
| `-replace` | Force recreate specific resource |
| `lifecycle.replace_triggered_by` | Auto-replace when dependency changes |
| Configuration change | Normal replacement due to immutable attribute change |
| `terraform state rm` + `apply` | Remove from state, then recreate |

### replace_triggered_by Alternative

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"
  # ...
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  lifecycle {
    # Automatically replace when security group changes
    replace_triggered_by = [aws_security_group.web.id]
  }
}
```

---

## State File Inspection

### Check for Tainted Resources

```bash
# List all resources and their status
terraform state pull | jq '.resources[] | select(.instances[].status == "tainted") | .type + "." + .name'

# Detailed view
terraform state pull | jq '.resources[] | {type, name, status: .instances[].status}'
```

---

## Automation and CI/CD

### Using -replace in CI/CD

```yaml
# GitLab CI example
deploy:
  script:
    - terraform init
    - terraform plan -replace="aws_instance.web" -out=tfplan
    - terraform apply tfplan
```

### Conditional Replacement

```bash
#!/bin/bash
# Replace only if health check fails

if ! curl -f http://instance-ip/health; then
  echo "Health check failed, replacing instance"
  terraform apply -replace="aws_instance.web" -auto-approve
fi
```

---

## Best Practices

1. **Use `-replace` instead of `taint`** - It's the modern, recommended approach
2. **Preview first** - Always run `terraform plan -replace=...` before applying
3. **Document the reason** - Leave comments or commit messages explaining why
4. **Consider lifecycle rules** - `replace_triggered_by` for automatic replacement
5. **Test in non-prod** - Verify replacement behavior before production
6. **Use with caution** - Replacement causes downtime unless using create_before_destroy

---

## Common Issues

### Issue: Replacement Causes Downtime

**Solution:** Use `create_before_destroy`:

```hcl
lifecycle {
  create_before_destroy = true
}
```

### Issue: Dependent Resources Also Replaced

**Solution:** Check dependencies and use targeted apply if needed:

```bash
terraform apply -replace="aws_instance.web" -target="aws_instance.web"
```

### Issue: Replacement Fails Midway

**Solution:** Check state and fix manually:

```bash
# Check current state
terraform state show aws_instance.web

# If stuck, remove from state and reimport
terraform state rm aws_instance.web
terraform import aws_instance.web i-newinstanceid
```

---

## Lab Exercise

1. Create an EC2 instance with Terraform
2. Use `terraform plan -replace` to preview replacement
3. Apply the replacement and observe the behavior
4. Add `create_before_destroy` and repeat
5. Set up `replace_triggered_by` with a security group
