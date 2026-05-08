# ============================================================
# Identity Module - Locals
#
# Centralizes all name construction and computed values.
# Follows naming convention: {prefix}-{environment}-{resource}
#
# This module creates:
#   - User Assigned Managed Identity (for AKS + jumpbox)
#   - Entra ID Admin Group (maps to AKS cluster admin role)
#   - Entra ID Dev Group   (maps to AKS namespace-level access)
# ============================================================

locals {
  # ── Name Prefix ──────────────────────────────────────────
  name_prefix = "${var.prefix}-${var.environment}"

  # ── Resource Names ────────────────────────────────────────
  identity_name    = "${local.name_prefix}-identity"
  admin_group_name = "AKS-${upper(var.environment)}-Admins"
  dev_group_name   = "AKS-${upper(var.environment)}-Developers"

  # ── Common Tags ───────────────────────────────────────────
  common_tags = merge(
    {
      environment = var.environment
      project     = var.project
      module      = "identity"
      managed_by  = "terraform"
      owner       = var.owner
    },
    var.tags
  )
}