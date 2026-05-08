# ============================================================
# Identity Module - Outputs
#
# Exposes identity resource attributes consumed by:
#   - AKS module      → identity_id, admin_group_object_id
#   - Jumpbox module  → identity_id
#   - Root module     → for display and documentation
# ============================================================

output "identity_id" {
  description = "Resource ID of the User Assigned Managed Identity — passed to AKS and jumpbox modules"
  value       = azurerm_user_assigned_identity.aks.id
}

output "identity_client_id" {
  description = "Client ID of the Managed Identity — used for workload identity federation"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "identity_principal_id" {
  description = "Principal ID of the Managed Identity — used for role assignments"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "admin_group_object_id" {
  description = "Object ID of the AKS Admin Entra ID group — passed to AKS module for RBAC"
  value       = azuread_group.aks_admins.object_id
}

output "developer_group_object_id" {
  description = "Object ID of the AKS Developer Entra ID group"
  value       = azuread_group.aks_developers.object_id
}

output "admin_group_name" {
  description = "Display name of the AKS Admin group"
  value       = azuread_group.aks_admins.display_name
}

output "developer_group_name" {
  description = "Display name of the AKS Developer group"
  value       = azuread_group.aks_developers.display_name
}