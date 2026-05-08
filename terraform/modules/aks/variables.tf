# ============================================================
# AKS Module - Variables
#
# Controls all AKS cluster configuration.
# Dev and prod environments pass different values
# for node counts, VM sizes, and Kubernetes version.
# ============================================================

# ── Required Variables ────────────────────────────────────────

variable "prefix" {
  description = "Short prefix for all resource names (e.g. akslab)"
  type        = string

  validation {
    condition     = length(var.prefix) <= 10 && can(regex("^[a-z0-9]+$", var.prefix))
    error_message = "Prefix must be lowercase alphanumeric and max 10 characters."
  }
}

variable "environment" {
  description = "Deployment environment — dev or prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region for all AKS resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where AKS resources will be created"
  type        = string
}

variable "project" {
  description = "Project name used in tags"
  type        = string
}

variable "owner" {
  description = "Owner name or team used in tags"
  type        = string
}

# ── Identity Variables ────────────────────────────────────────

variable "identity_id" {
  description = <<-EOT
    Resource ID of the User Assigned Managed Identity.
    Used by AKS control plane to manage Azure resources
    (load balancers, disks, NICs) on your behalf.
  EOT
  type        = string
}

variable "identity_principal_id" {
  description = "Principal ID of the Managed Identity — used for ACR pull role assignment"
  type        = string
}

variable "admin_group_object_id" {
  description = <<-EOT
    Object ID of the Entra ID Admin group.
    This group gets Azure Kubernetes Service RBAC Cluster Admin role.
  EOT
  type        = string
}

# ── Networking Variables ──────────────────────────────────────

variable "aks_subnet_id" {
  description = "Resource ID of the AKS subnet — nodes and pods get IPs from here"
  type        = string
}

# ── Cluster Variables ─────────────────────────────────────────

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster and node pools"
  type        = string
  default     = "1.29"
}

variable "system_node_count" {
  description = <<-EOT
    Number of nodes in the system node pool.
    Dev:  2 (minimum for HA)
    Prod: 3 (odd number for etcd quorum)
  EOT
  type        = number

  validation {
    condition     = var.system_node_count >= 1
    error_message = "System node count must be at least 1."
  }
}

variable "system_vm_size" {
  description = <<-EOT
    VM size for system node pool.
    Dev:  Standard_D2s_v3 (2 vCPU, 8GB RAM)
    Prod: Standard_D4s_v3 (4 vCPU, 16GB RAM)
  EOT
  type        = string
}

variable "user_node_count" {
  description = <<-EOT
    Number of nodes in the user node pool.
    Runs application workloads (myapp, bookinfo, istio).
    Dev:  2
    Prod: 3
  EOT
  type        = number

  validation {
    condition     = var.user_node_count >= 1
    error_message = "User node count must be at least 1."
  }
}

variable "user_vm_size" {
  description = <<-EOT
    VM size for user node pool.
    Needs enough resources for Istio sidecars + app containers.
    Dev:  Standard_D2s_v3
    Prod: Standard_D4s_v3
  EOT
  type        = string
}

# ── Optional Variables ────────────────────────────────────────

variable "tags" {
  description = "Additional tags to merge with module common tags"
  type        = map(string)
  default     = {}
}