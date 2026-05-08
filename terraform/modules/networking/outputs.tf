# ============================================================
# Networking Module - Outputs
#
# Exposes resource IDs and names so downstream modules
# (aks, jumpbox, identity) can reference them without
# hardcoding any values.
#
# Usage in environment main.tf:
#   module.networking.aks_subnet_id
#   module.networking.vnet_name
# ============================================================

output "vnet_id" {
  description = "Resource ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "aks_subnet_id" {
  description = "Resource ID of the AKS subnet — passed to the AKS module"
  value       = azurerm_subnet.aks.id
}

output "jumpbox_subnet_id" {
  description = "Resource ID of the Jumpbox subnet — passed to the jumpbox module"
  value       = azurerm_subnet.jumpbox.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion host — used in az network bastion ssh commands"
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}

output "nsg_aks_id" {
  description = "Resource ID of the AKS subnet NSG"
  value       = azurerm_network_security_group.aks.id
}