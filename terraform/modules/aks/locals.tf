# ============================================================
# AKS Module - Locals
#
# Centralizes all name construction and computed values.
#
# This module creates:
#   - Private AKS cluster (no public API server)
#   - System node pool    (runs kube-system workloads)
#   - User node pool      (runs application workloads)
#   - ACR                 (private container registry)
#   - Log Analytics       (cluster monitoring)
#   - Key Vault           (secrets management)
# ============================================================

locals {
  # ── Name Prefix ───────────────────────────────────────────
  name_prefix = "${var.prefix}-${var.environment}"

  # ── Resource Names ────────────────────────────────────────
  aks_name = "${local.name_prefix}-aks"
  acr_name = "${replace(local.name_prefix, "-", "")}acr" # ACR allows no hyphens
  law_name = "${local.name_prefix}-law"
  kv_name  = "${local.name_prefix}-kv"

  # ── Node Pool Settings ────────────────────────────────────
  # System pool: reserved for kube-system pods only
  # User pool:   runs application workloads (myapp, bookinfo)
  # Separation prevents app workloads from starving system pods
  system_node_pool_name = "system"
  user_node_pool_name   = "user"

  # ── Common Tags ───────────────────────────────────────────
  common_tags = merge(
    {
      environment = var.environment
      project     = var.project
      module      = "aks"
      managed_by  = "terraform"
      owner       = var.owner
    },
    var.tags
  )
}