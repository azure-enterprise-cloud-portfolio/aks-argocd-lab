# ============================================================
# Identity Module - Main
#
# Creates the identity foundation for the AKS lab:
#
#   User Assigned Managed Identity
#   └── Used by AKS control plane + jumpbox VM
#
#   Entra ID Admin Group
#   └── Members: Platform/DevOps engineers
#   └── Role assigned in envs/dev/main.tf (needs AKS ID)
#
#   Entra ID Developer Group
#   └── Members: Application developers
#   └── Role assigned in envs/dev/main.tf (needs AKS ID)
#
# Why role assignments are NOT here:
#   Role assignments need AKS cluster ID.
#   AKS needs identity ID from this module.
#   Keeping roles here creates a circular dependency.
#   Solution: roles assigned in root main.tf after AKS is created.
# ============================================================

data "azuread_client_config" "current" {}

# ── User Assigned Managed Identity ───────────────────────────
# Used by AKS control plane to manage Azure resources.
# Used by jumpbox to authenticate via az login --identity.
resource "azurerm_user_assigned_identity" "aks" {
  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

# ── Entra ID Admin Group ──────────────────────────────────────
# Full cluster-admin access.
# Role assignment scoped to AKS cluster — done in root main.tf.
resource "azuread_group" "aks_admins" {
  display_name     = local.admin_group_name
  description      = "AKS ${var.environment} cluster administrators"
  security_enabled = true
}

# ── Add Terraform Deployer to Admin Group ─────────────────────
# Prevents being locked out after deployment.
resource "azuread_group_member" "deployer_admin" {
  group_object_id  = azuread_group.aks_admins.object_id
  member_object_id = data.azuread_client_config.current.object_id
}

# ── Add Extra Admin Members ───────────────────────────────────
resource "azuread_group_member" "admins" {
  for_each = toset(var.admin_group_members)

  group_object_id  = azuread_group.aks_admins.object_id
  member_object_id = each.value
}

# ── Entra ID Developer Group ──────────────────────────────────
# Namespace-scoped access only.
# Role assignment scoped to AKS cluster — done in root main.tf.
resource "azuread_group" "aks_developers" {
  display_name     = local.dev_group_name
  description      = "AKS ${var.environment} developers — namespace-level access only"
  security_enabled = true
}

# ── Add Developer Members ─────────────────────────────────────
resource "azuread_group_member" "developers" {
  for_each = toset(var.dev_group_members)

  group_object_id  = azuread_group.aks_developers.object_id
  member_object_id = each.value
}