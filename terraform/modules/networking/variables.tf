# ============================================================
# Networking Module - Variables
#
# All inputs are validated to catch misconfiguration early.
# No variable has a default that could silently cause issues
# in production (e.g. environment has no default).
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
  description = "Deployment environment — controls naming and behaviour"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region for all resources (e.g. canadacentral)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy networking resources into"
  type        = string
}

variable "project" {
  description = "Project name used in tags (e.g. aks-argocd-lab)"
  type        = string
}

variable "owner" {
  description = "Owner name or team used in tags (e.g. platform-team)"
  type        = string
}

# ── Network CIDR Variables ────────────────────────────────────

variable "vnet_address_space" {
  description = <<-EOT
    CIDR block for the Virtual Network.
    Must be large enough to contain all subnets.
    Dev:  10.0.0.0/8
    Prod: 10.0.0.0/8
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "vnet_address_space must be a valid CIDR block."
  }
}

variable "aks_subnet_prefix" {
  description = <<-EOT
    CIDR for the AKS subnet.
    With Azure CNI, each pod gets a real VNet IP.
    Size based on: node_count x max_pods_per_node.
    Recommended minimum: /16 for flexibility.
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.aks_subnet_prefix, 0))
    error_message = "aks_subnet_prefix must be a valid CIDR block."
  }
}

variable "jumpbox_subnet_prefix" {
  description = <<-EOT
    CIDR for the Jumpbox subnet.
    Only 1 VM lives here — /24 is more than enough.
    Isolated from AKS subnet for security segmentation.
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.jumpbox_subnet_prefix, 0))
    error_message = "jumpbox_subnet_prefix must be a valid CIDR block."
  }
}

variable "bastion_subnet_prefix" {
  description = <<-EOT
    CIDR for the Azure Bastion subnet.
    MUST be named AzureBastionSubnet (enforced in main.tf).
    Azure requires minimum /27 (32 IPs) for Bastion to deploy.
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.bastion_subnet_prefix, 0))
    error_message = "bastion_subnet_prefix must be a valid CIDR block."
  }
}

# ── Optional Variables ────────────────────────────────────────

variable "tags" {
  description = "Additional tags to merge with module common tags"
  type        = map(string)
  default     = {}
}