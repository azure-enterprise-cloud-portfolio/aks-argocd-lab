# ============================================================
# Networking Module - Locals
#
# All name construction and computed values live here.
# main.tf references locals only — no hardcoded strings.
#
# Naming convention: {prefix}-{environment}-{resource}
# Example: akslab-dev-vnet, akslab-prod-snet-aks
# ============================================================

locals {
  # ── Name Prefix ─────────────────────────────────────────
  # Used as base for all resource names in this module
  name_prefix = "${var.prefix}-${var.environment}"

  # ── Resource Names ───────────────────────────────────────
  vnet_name           = "${local.name_prefix}-vnet"
  aks_subnet_name     = "${local.name_prefix}-snet-aks"
  jumpbox_subnet_name = "${local.name_prefix}-snet-jumpbox"
  bastion_pip_name    = "${local.name_prefix}-bastion-pip"
  bastion_name        = "${local.name_prefix}-bastion"
  nsg_aks_name        = "${local.name_prefix}-nsg-aks"

  # ── Common Tags ──────────────────────────────────────────
  # Merged with any extra tags passed in from the environment.
  # Module-level tags are always applied; caller can extend them.
  common_tags = merge(
    {
      environment = var.environment
      project     = var.project
      module      = "networking"
      managed_by  = "terraform"
      owner       = var.owner
    },
    var.tags
  )
}