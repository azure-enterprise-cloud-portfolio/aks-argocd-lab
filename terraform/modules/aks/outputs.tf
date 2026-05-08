# ============================================================
# AKS Module - Outputs
#
# Exposes cluster details consumed by:
#   - Identity module  → aks_id for role assignments
#   - Root module      → connection commands, display
#   - GitHub Actions   → cluster name for kubectl commands
# ============================================================

output "aks_id" {
  description = "Resource ID of the AKS cluster — used for role assignments in identity module"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  description = "Name of the AKS cluster — used in az aks get-credentials command"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  description = "ACR login server URL — used to tag and push Docker images"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "key_vault_name" {
  description = "Name of the Key Vault — used in SecretProviderClass manifests"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.id
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster — marked sensitive"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true # Never printed in terraform output or logs
}

output "aks_node_resource_group" {
  description = "Auto-generated resource group where AKS node VMs are created"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}