# ============================================================
# Networking Module - Main
#
# Deploys the full network topology for the AKS private lab:
#
#   VNet
#   ├── snet-aks        → AKS nodes + pods (Azure CNI)
#   ├── snet-jumpbox    → Admin jumpbox VM
#   └── AzureBastionSubnet → Azure Bastion
#
# Access pattern (no public IPs except Bastion):
#   Laptop ──HTTPS──▶ Bastion ──SSH──▶ Jumpbox ──▶ Private AKS
#
# Security posture:
#   - NSG on AKS subnet: deny-all inbound by default
#   - K8s NetworkPolicies handle pod-level traffic (see AKS module)
#   - No public IP on jumpbox or AKS nodes
# ============================================================

# ── Virtual Network ───────────────────────────────────────────
# Top-level network container. All subnets live inside this VNet.
# A single VNet per environment keeps routing simple.
resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_space]
  tags                = local.common_tags
}

# ── AKS Subnet ────────────────────────────────────────────────
# AKS nodes and pods get IPs from this subnet (Azure CNI).
# Must be large enough for: max_nodes × max_pods_per_node.
# Example: 10 nodes × 30 pods = 300 IPs minimum.
resource "azurerm_subnet" "aks" {
  name                 = local.aks_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_prefix]
}

# ── Jumpbox Subnet ────────────────────────────────────────────
# Admin VM subnet — physically separated from AKS workloads.
# Only the jumpbox VM lives here.
# Traffic to AKS API server flows: jumpbox → private endpoint.
resource "azurerm_subnet" "jumpbox" {
  name                 = local.jumpbox_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.jumpbox_subnet_prefix]
}

# ── Bastion Subnet ────────────────────────────────────────────
# WARNING: Azure enforces the exact name "AzureBastionSubnet".
# Renaming this will cause Bastion deployment to fail.
# Minimum CIDR: /27 — Azure Bastion internally reserves IPs.
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet" # Azure-enforced name — do not change
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

# ── Bastion Public IP ─────────────────────────────────────────
# The ONLY public-facing resource in this entire lab.
# Must be Standard SKU and Static allocation for Bastion.
# Everything else (AKS, jumpbox, ACR, Key Vault) is private.
resource "azurerm_public_ip" "bastion" {
  name                = local.bastion_pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"   # Required for Bastion
  sku                 = "Standard" # Required for Bastion
  tunneling_enabled   = true       # Required for native client SSH
  tags                = local.common_tags
}

# ── Azure Bastion Host ────────────────────────────────────────
# Provides browser-based SSH/RDP over HTTPS — no open SSH port needed.
# Eliminates the need for public IPs on the jumpbox entirely.
# Access: Azure Portal → Bastion → Connect to jump