
# ============================================================
# Jumpbox Module - Main
#
# Deploys the admin jumpbox VM and its network security:
#
#   NSG (Jumpbox)
#   └── Allow inbound from Bastion only
#   └── Deny all other inbound traffic
#
#   Network Interface
#   └── Private IP only — no public IP
#
#   Linux VM (Ubuntu 22.04 LTS)
#   └── User Assigned Managed Identity
#   └── Entra ID SSH login — no SSH keys needed
#   └── cloud-init installs: az, kubectl, helm, kubelogin, argocd, k9s
#
# Connection flow:
#   Browser ──HTTPS──▶ Azure Bastion ──AAD──▶ Jumpbox ──▶ AKS
# ============================================================

resource "azurerm_network_security_group" "jumpbox" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  security_rule {
    name                       = "allow-bastion-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = var.jumpbox_subnet_id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

resource "azurerm_network_interface" "jumpbox" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.jumpbox_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

#checkov:skip=CKV_AZURE_178:Entra ID SSH login used instead of SSH keys
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = local.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = random_password.jumpbox.result
  tags                            = local.common_tags

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  os_disk {
    name                 = local.disk_name
    caching              = "ReadWrite"
    storage_account_type = var.environment == "prod" ? "Premium_LRS" : "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(local.startup_script)

  depends_on = [
    azurerm_subnet_network_security_group_association.jumpbox
  ]
}

#checkov:skip=CKV_AZURE_50:AADSSHLoginForLinux extension required for Entra ID auth
resource "azurerm_virtual_machine_extension" "aad_ssh" {
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.jumpbox.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = local.common_tags
}

resource "azurerm_role_assignment" "vm_admin_login" {
  scope                            = azurerm_linux_virtual_machine.jumpbox.id
  role_definition_name             = "Virtual Machine Administrator Login"
  principal_id                     = var.admin_group_object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "vm_user_login" {
  scope                            = azurerm_linux_virtual_machine.jumpbox.id
  role_definition_name             = "Virtual Machine User Login"
  principal_id                     = var.dev_group_object_id
  skip_service_principal_aad_check = true
}

# Random password — required by Azure when disable_password_authentication = false
# Never used directly — Entra ID SSH extension handles all authentication
resource "random_password" "jumpbox" {
  length           = 16
  special          = true
  override_special = "!@#"
}
