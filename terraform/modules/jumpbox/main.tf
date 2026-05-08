# ============================================================
# Jumpbox Module - Main
#
# Deploys the admin jumpbox VM and its network security:
#
#   NSG (Jumpbox)
#   └── Allow inbound from AzureBastion service tag only
#   └── Deny all other inbound traffic
#
#   Network Interface
#   └── Private IP only — no public IP
#
#   Linux VM (Ubuntu 22.04 LTS)
#   └── User Assigned Managed Identity (no passwords to Azure)
#   └── SSH key auth only (no password auth)
#   └── cloud-init installs: az, kubectl, helm, kubelogin, argocd, k9s
#
# Connection flow:
#   Browser ──HTTPS──▶ Azure Bastion ──SSH──▶ Jumpbox ──▶ AKS
# ============================================================

# ── NSG for Jumpbox Subnet ────────────────────────────────────
# Restricts inbound traffic to the jumpbox subnet.
# Only Azure Bastion service tag is allowed — all else denied.
# This means the jumpbox is ONLY reachable through Bastion.
resource "azurerm_network_security_group" "jumpbox" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  # Allow SSH only from Azure Bastion service
  # AzureBastionSubnet uses service tag "AzureBastion" internally
  security_rule {
    name                       = "allow-bastion-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "AzureBastionSubnet" # Only from Bastion subnet
    destination_address_prefix = "*"
  }

  # Deny everything else inbound
  # No direct SSH from internet — must go through Bastion
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

# ── NSG Association ───────────────────────────────────────────
# Binds the jumpbox NSG to the jumpbox subnet.
resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = var.jumpbox_subnet_id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

# ── Network Interface ─────────────────────────────────────────
# Private IP only — no public IP address assigned.
# Dynamic private IP from the jumpbox subnet CIDR.
# The jumpbox is invisible from the internet.
resource "azurerm_network_interface" "jumpbox" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.jumpbox_subnet_id
    private_ip_address_allocation = "Dynamic" # Azure assigns from subnet range
  }
}

# ── Linux Virtual Machine ─────────────────────────────────────
# Ubuntu 22.04 LTS jumpbox VM.
# Bootstrapped with cloud-init to install all K8s tools.
# Authenticated to Azure via Managed Identity (no az login needed).
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = local.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true # SSH key only — no password auth
  tags                            = local.common_tags

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id
  ]

  # ── Managed Identity ────────────────────────────────────
  # Assigns the shared identity to the jumpbox VM.
  # Inside the VM: az login --identity
  # This authenticates as the Managed Identity — no secrets needed.
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # ── SSH Key Auth ─────────────────────────────────────────
  # Public key injected at VM creation.
  # Private key stays on your laptop — never leaves your machine.

  # ── OS Disk ──────────────────────────────────────────────
  # Standard LRS is sufficient for jumpbox (not running workloads).
  # Premium SSD used in prod for faster boot times.
  os_disk {
    name                 = local.disk_name
    caching              = "ReadWrite"
    storage_account_type = var.environment == "prod" ? "Premium_LRS" : "Standard_LRS"
  }

  # ── Image ────────────────────────────────────────────────
  # Ubuntu 22.04 LTS — long term support until 2027.
  # Latest patch version auto-selected by Azure.
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # ── Cloud Init (custom_data) ──────────────────────────────
  # Runs on first boot — installs kubectl, helm, argocd, etc.
  # Script defined in locals.tf for cleanliness.
  # Logs written to: /var/log/jumpbox-init.log
  # Ready indicator: /tmp/jumpbox-ready
  custom_data = base64encode(local.startup_script)

  depends_on = [
    azurerm_subnet_network_security_group_association.jumpbox
  ]
}
# VM Administrator Login — Admin group gets sudo access
resource "azurerm_role_assignment" "vm_admin_login" {
  scope                            = azurerm_linux_virtual_machine.jumpbox.id
  role_definition_name             = "Virtual Machine Administrator Login"
  principal_id                     = var.admin_group_object_id
  skip_service_principal_aad_check = true
}

# VM User Login — Developer group gets regular access
resource "azurerm_role_assignment" "vm_user_login" {
  scope                            = azurerm_linux_virtual_machine.jumpbox.id
  role_definition_name             = "Virtual Machine User Login"
  principal_id                     = var.dev_group_object_id
  skip_service_principal_aad_check = true
}
