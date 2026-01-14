# ============================================================
# Vault Policy - Admin Access
# ============================================================
# Full administrative access - use sparingly!
# ============================================================

# Manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage auth methods
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage policies
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List policies
path "sys/policy" {
  capabilities = ["read", "list"]
}

# Read system health
path "sys/health" {
  capabilities = ["read"]
}

# Manage all secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage Kubernetes auth
path "auth/kubernetes/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage tokens
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
