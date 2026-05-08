# ============================================================
# Jumpbox Module - Outputs
#
# Exposes jumpbox details used by:
#   - Root module outputs → connection instructions
#   - GitHub Actions      → verify jumpbox is ready
# ============================================================

output "jumpbox_name" {
  description = "Name of the jumpbox VM — used in az network bastion ssh command"
  value       = azurerm_linux_virtual_machine.jumpbox.name
}

output "jumpbox_id" {
  description = "Resource ID of the jumpbox VM — required for az network bastion ssh"
  value       = azurerm_linux_virtual_machine.jumpbox.id
}

output "jumpbox_private_ip" {
  description = "Private IP address of the jumpbox VM"
  value       = azurerm_network_interface.jumpbox.ip_configuration[0].private_ip_address
}

output "connection_command" {
  description = "Ready-to-run command to connect to the jumpbox via Azure Bastion"
  value       = <<-EOT
    az network bastion ssh \
      --name ${var.bastion_name} \
      --resource-group ${var.resource_group_name} \
      --target-resource-id ${azurerm_linux_virtual_machine.jumpbox.id} \
      --auth-type ssh-key \
      --username ${var.admin_username} \
      --ssh-key ~/.ssh/id_rsa
  EOT
}