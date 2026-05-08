# =============================================================================
# Dev Environment - Root Module
#
# Module order (dependency chain):
#   1. resource_group → no dependencies
#   2. identity       → creates Managed Identity + Entra ID groups only
#   3. networking     → needs resource group
#   4. aks            → needs identity + networking
#   5. role_assignments → needs aks (for cluster ID) — assigns RBAC roles
#   6. jumpbox        → needs networking + identity
#
# Circular dependency broken by:
#   identity module  → creates identity + groups (no AKS dependency)
#   role assignments → done in root main.tf after AKS is created
# =============================================================================

# ── Resource Group ────────────────────────────────────────────
# Created directly — it is the container for all resources.
# No module needed for a single resource with no complex logic.
resource "azurerm_resource_group" "rg" {
  provider = azurerm.dev
  name     = local.resource_group_name
  location = var.location

  tags = merge(
    {
      environment = var.environment
      project     = var.project
      managed_by  = "terraform"
      owner       = var.owner
    },
    local.environment_tags
  )
}

# ── Identity ──────────────────────────────────────────────────
# Creates Managed Identity + Entra ID groups ONLY.
# Role assignments are done below after AKS is created
# to avoid circular dependency between identity and AKS modules.
module "identity" {
  source = "../../modules/identity"
  providers = {
    azurerm = azurerm.dev
    azuread = azuread
  }

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  project             = var.project
  owner               = var.owner
  resource_group_name = azurerm_resource_group.rg.name
  admin_group_members = var.admin_group_members
  dev_group_members   = var.dev_group_members
  tags                = local.environment_tags

  depends_on = [azurerm_resource_group.rg]
}

# ── Networking ────────────────────────────────────────────────
# Deploys: VNet, subnets, Bastion, NSGs.
# Output used by: AKS module, Jumpbox module.
module "networking" {
  source = "../../modules/networking"
  providers = {
    azurerm = azurerm.dev
  }

  prefix                = var.prefix
  environment           = var.environment
  location              = var.location
  project               = var.project
  owner                 = var.owner
  resource_group_name   = azurerm_resource_group.rg.name
  vnet_address_space    = local.vnet_address_space
  aks_subnet_prefix     = local.aks_subnet_prefix
  jumpbox_subnet_prefix = local.jumpbox_subnet_prefix
  bastion_subnet_prefix = local.bastion_subnet_prefix
  tags                  = local.environment_tags

  depends_on = [azurerm_resource_group.rg]
}

# ── AKS ───────────────────────────────────────────────────────
# Deploys: AKS cluster, ACR, Key Vault, Log Analytics.
# Depends on identity (needs managed identity ID)
# Depends on networking (needs subnet ID)
module "aks" {
  source = "../../modules/aks"
  providers = {
    azurerm = azurerm.dev
  }

  prefix                = var.prefix
  environment           = var.environment
  location              = var.location
  project               = var.project
  owner                 = var.owner
  resource_group_name   = azurerm_resource_group.rg.name
  identity_id           = module.identity.identity_id
  identity_principal_id = module.identity.identity_principal_id
  admin_group_object_id = module.identity.admin_group_object_id
  aks_subnet_id         = module.networking.aks_subnet_id
  kubernetes_version    = "1.35.3"
  system_node_count     = local.system_node_count
  system_vm_size        = local.system_vm_size
  user_node_count       = local.user_node_count
  user_vm_size          = local.user_vm_size
  tags                  = local.environment_tags

  depends_on = [module.networking, module.identity]
}

# ── Role Assignments ──────────────────────────────────────────
# Assigns Entra ID groups to AKS cluster AFTER AKS is created.
#
# Why here and not in identity module?
#   identity module needs to run before AKS (provides identity_id)
#   role assignments need AKS cluster ID (only available after AKS)
#   putting roles in identity module would create a circular dependency
#
# Admin group → full cluster-admin access
resource "azurerm_role_assignment" "aks_cluster_admin" {
  provider             = azurerm.dev
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = module.identity.admin_group_object_id

  skip_service_principal_aad_check = true

  depends_on = [module.aks, module.identity]
}

# Developer group → namespace-level writer access only
resource "azurerm_role_assignment" "aks_developer" {
  provider             = azurerm.dev
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = module.identity.developer_group_object_id

  skip_service_principal_aad_check = true

  depends_on = [module.aks, module.identity]
}

# ── Jumpbox ───────────────────────────────────────────────────
# Deploys: Ubuntu VM, NIC, NSG, Entra ID SSH extension.
# Engineers connect via: az network bastion ssh --auth-type AAD
# No SSH keys — access controlled by Entra ID group membership.
module "jumpbox" {
  source = "../../modules/jumpbox"
  providers = {
    azurerm = azurerm.dev
  }

  prefix                = var.prefix
  environment           = var.environment
  location              = var.location
  project               = var.project
  owner                 = var.owner
  resource_group_name   = azurerm_resource_group.rg.name
  jumpbox_subnet_id     = module.networking.jumpbox_subnet_id
  bastion_name          = module.networking.bastion_name
  identity_id           = module.identity.identity_id
  vm_size               = local.jumpbox_vm_size
  admin_username        = "azureuser"
  admin_group_object_id = module.identity.admin_group_object_id
  dev_group_object_id   = module.identity.developer_group_object_id
  tags                  = local.environment_tags

  depends_on = [module.networking, module.identity]
}