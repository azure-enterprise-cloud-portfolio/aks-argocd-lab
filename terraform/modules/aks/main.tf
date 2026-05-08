
# ============================================================
# AKS Module - Main
#
# Deploys the full AKS platform stack:
#
#   Log Analytics Workspace  → cluster monitoring + insights
#   Azure Container Registry → private image registry
#   Key Vault                → secrets storage (CSI driver)
#   AKS Cluster              → private, Entra ID RBAC enabled
#   ├── System Node Pool     → kube-system workloads only
#   └── User Node Pool       → application workloads
#
# Security highlights:
#   - Private cluster: API server has no public endpoint
#   - Azure CNI: pods get real VNet IPs (not overlay network)
#   - Network policy: Azure CNI policy engine (not Calico)
#   - Entra ID RBAC: Azure AD groups map to K8s roles
#   - Key Vault CSI: secrets mounted as volumes (not env vars)
#   - Managed Identity: no passwords or service principal keys
# ============================================================


# ── Log Analytics Workspace ───────────────────────────────────
# Collects cluster logs, metrics, and container insights.
# Connected to AKS via oms_agent block below.
# Used to: query pod logs, set alerts, monitor node health.
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.law_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018" # Pay per GB — most cost effective for labs
  retention_in_days   = 30          # Minimum retention — increase for prod
  tags                = local.common_tags
}

# ── Azure Container Registry ──────────────────────────────────
# Private registry for storing Docker images.
# AKS pulls images from here using Managed Identity (no password).
# ACR name: no hyphens allowed — stripped in locals.tf
resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard" # Standard supports geo-replication in prod
  admin_enabled       = false      # Disabled — use Managed Identity instead
  tags                = local.common_tags
}

# ── ACR Pull Role Assignment ──────────────────────────────────
# Grants the AKS Managed Identity permission to pull images from ACR.
# Without this, AKS nodes cannot pull private images.
# Role: AcrPull — read-only access to registry (not push/delete)
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = var.identity_principal_id

  skip_service_principal_aad_check = true
}

# ── Key Vault ─────────────────────────────────────────────────
# Stores secrets that pods consume via the CSI Secrets Store driver.
# Secrets are mounted as files — never stored as K8s secrets.
# Access policy: only the Managed Identity can read secrets.
/*
resource "azurerm_key_vault" "kv" {
  name                       = local.kv_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # Set true in prod
  tags                       = local.common_tags

  # Allow Terraform deployer to manage secrets (set/get/delete)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "Set", "List", "Delete", "Purge", "Recover"
    ]
  }

  # Allow AKS Managed Identity to read secrets (pods)
  # This is what the CSI driver uses to mount secrets into pods
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.identity_principal_id

    secret_permissions = ["Get", "List"]
  }
}

# ── Store a sample secret ─────────────────────────────────────
# Demo secret to verify CSI driver works end-to-end.
# In real workloads: database passwords, API keys, etc.
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = "SuperSecret123!" # Replace with real secret in prod
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

*/

# ── AKS Cluster ───────────────────────────────────────────────
# Private cluster: API server is only reachable inside the VNet.
# Access pattern: Laptop → Bastion → Jumpbox → AKS API server
resource "azurerm_kubernetes_cluster" "aks" {
  name                    = local.aks_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = local.aks_name
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = true # No public API server endpoint
  tags                    = local.common_tags

  # ── System Node Pool ──────────────────────────────────────
  # Runs kube-system pods only (CoreDNS, kube-proxy, etc.)
  # Tainted with CriticalAddonsOnly to prevent app scheduling.
  # Kept small — only system components run here.
  default_node_pool {
    name            = local.system_node_pool_name
    node_count      = var.system_node_count
    vm_size         = var.system_vm_size
    vnet_subnet_id  = var.aks_subnet_id
    os_disk_size_gb = 50
    type            = "VirtualMachineScaleSets"

    # Reserve system pool for system workloads only
    # App pods will be scheduled on the user node pool

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }

    tags = local.common_tags
  }

  # ── Managed Identity ──────────────────────────────────────
  # User Assigned identity — same one used by jumpbox.
  # Controls Azure resources on behalf of AKS:
  #   load balancers, public IPs, disks, NICs
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # ── Network Profile ───────────────────────────────────────
  # Azure CNI: each pod gets a real VNet IP (not overlay).
  # Enables direct pod-to-pod communication across nodes.
  # Network policy: enforces K8s NetworkPolicy objects.
  network_profile {
    network_plugin    = "azure" # Azure CNI — pods get VNet IPs
    network_policy    = "azure" # Enforces K8s NetworkPolicy
    load_balancer_sku = "standard"
  }

  # ── Entra ID RBAC ─────────────────────────────────────────
  # Maps Entra ID groups to K8s RBAC roles.
  # azure_rbac_enabled: use Azure RBAC instead of local K8s RBAC.
  # admin_group_object_ids: these groups get cluster-admin.
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = [var.admin_group_object_id]
  }

  # ── Key Vault CSI Driver ──────────────────────────────────
  # Enables mounting Key Vault secrets as pod volume mounts.
  # secret_rotation_enabled: auto-refreshes secrets in pods
  # when Key Vault values change (no pod restart needed).
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # ── OMS Agent (Azure Monitor) ─────────────────────────────
  # Ships container logs and metrics to Log Analytics.
  # Enables Container Insights dashboards in Azure Portal.
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}

# ── User Node Pool ────────────────────────────────────────────
# Separate pool for application workloads.
# Isolated from system pool — app issues don't affect kube-system.
# ArgoCD, myapp, bookinfo, and Istio all run here.
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = local.user_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = 50
  mode                  = "User" # Accepts application workloads

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload"      = "apps"
  }

  # Taint to separate from system pool if needed
  # Uncomment to force all app pods to this pool:
  # node_taints = ["workload=user:NoSchedule"]

  tags = local.common_tags
}