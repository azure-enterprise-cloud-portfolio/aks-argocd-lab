# ============================================================
# Dev Environment - Locals
#
# Dev-specific computed values and size configurations.
# Dev is intentionally smaller/cheaper than prod:
#   - Smaller VM sizes
#   - Fewer nodes
#   - Auto ArgoCD sync (no manual approval gate)
# ============================================================

locals {
  # ── Resource Group Name ───────────────────────────────────
  resource_group_name = "${var.prefix}-${var.environment}-rg"

  # ── Network CIDRs ─────────────────────────────────────────
  # Dev uses 10.0.0.0/8 VNet split into subnets
  vnet_address_space    = "10.0.0.0/8"
  aks_subnet_prefix     = "10.240.0.0/16"
  jumpbox_subnet_prefix = "10.241.0.0/24"
  bastion_subnet_prefix = "10.242.0.0/27"

  # ── Node Pool Sizes ───────────────────────────────────────
  # Dev: minimum nodes to save cost
  # System pool: 2 nodes (minimum for HA)
  # User pool:   2 nodes (runs apps + Istio sidecars)
  system_node_count = 2
  system_vm_size    = "Standard_D2s_v3" # 2 vCPU, 8GB RAM

  user_node_count = 2
  user_vm_size    = "Standard_D2s_v3" # 2 vCPU, 8GB RAM

  # ── Jumpbox ───────────────────────────────────────────────
  jumpbox_vm_size = "Standard_B1s" # 1 vCPU, 1GB RAM — enough for kubectl

  # ── Dev Environment Tags ──────────────────────────────────
  environment_tags = {
    cost-center   = "engineering"
    auto-shutdown = "true" # Tag for auto-shutdown policy in dev
  }
}