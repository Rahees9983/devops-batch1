# ============================================================
# Vault Policy for ArgoCD Vault Plugin
# ============================================================
# This policy grants read access to secrets for ArgoCD
# ============================================================

# Allow reading all secrets in the KV v2 secrets engine
path "secret/data/*" {
  capabilities = ["read", "list"]
}

# Allow listing secrets
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}

# If using specific paths per application, use more restrictive policies:
# path "secret/data/production/*" {
#   capabilities = ["read"]
# }
# path "secret/data/staging/*" {
#   capabilities = ["read"]
# }
