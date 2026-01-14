# ============================================================
# Vault Policy - Application Read-Only Access
# ============================================================
# Use this as a template for application-specific policies
# ============================================================

# Read-only access to application secrets
path "secret/data/myapp/*" {
  capabilities = ["read"]
}

# Allow listing secrets in the app path
path "secret/metadata/myapp/*" {
  capabilities = ["list"]
}

# Read database credentials (if using dynamic secrets)
path "database/creds/myapp-role" {
  capabilities = ["read"]
}

# Read AWS credentials (if using AWS secrets engine)
path "aws/creds/myapp-role" {
  capabilities = ["read"]
}
