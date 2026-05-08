# ============================================================
# Dev Environment - Outputs
#
# Displayed after terraform apply completes.
# Provides all commands needed to connect and verify
# the deployed infrastructure.
# ============================================================

output "resource_group_name" {
  description = "Resource group containing all dev resources"
  value       = azurerm_resource_group.rg.name
}

output "aks_name" {
  description = "AKS cluster name"
  value       = module.aks.aks_name
}

output "acr_login_server" {
  description = "ACR login server — use this to tag and push images"
  value       = module.aks.acr_login_server
}

# output "key_vault_name" {
#   description = "Key Vault name — use in SecretProviderClass manifests"
#   value       = module.aks.key_vault_name
# }

output "jumpbox_private_ip" {
  description = "Private IP of the jumpbox VM"
  value       = module.jumpbox.jumpbox_private_ip
}

output "bastion_name" {
  description = "Azure Bastion name"
  value       = module.networking.bastion_name
}

output "admin_group_name" {
  description = "Entra ID Admin group name"
  value       = module.identity.admin_group_name
}

output "developer_group_name" {
  description = "Entra ID Developer group name"
  value       = module.identity.developer_group_name
}

# ── Connection Instructions ───────────────────────────────────

output "step_1_get_credentials" {
  description = "Step 1 — Get AKS credentials (run inside jumpbox)"
  value       = <<-EOT

    # Get AKS credentials
    az login --identity
    az aks get-credentials \
      --resource-group ${azurerm_resource_group.rg.name} \
      --name ${module.aks.aks_name}
    kubelogin convert-kubeconfig -l azurecli
    kubectl get nodes
  EOT
}

output "step_2_connect_jumpbox" {
  description = "Step 2 — Connect to jumpbox via Bastion"
  value       = module.jumpbox.connection_command
}

output "kube_config" {
  description = "Raw kubeconfig — sensitive"
  value       = module.aks.kube_config
  sensitive   = true
}