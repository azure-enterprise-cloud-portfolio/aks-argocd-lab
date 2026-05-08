# ============================================================
# Jumpbox Module - Variables
#
# Controls the admin jumpbox VM configuration.
# Access via Azure Bastion + Entra ID — no SSH keys needed.
# Engineers authenticate with their own az login credentials.
# Access controlled by Entra ID group membership.
# ============================================================

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
  description = "Azure region for the jumpbox VM"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the jumpbox will be created"
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

variable "jumpbox_subnet_id" {
  description = "Resource ID of the jumpbox subnet"
  type        = string
}

variable "identity_id" {
  description = "Resource ID of the User Assigned Managed Identity"
  type        = string
}



variable "admin_username" {
  description = "Linux admin username for the jumpbox VM"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "VM size for the jumpbox"
  type        = string
  default     = "Standard_B1s"
}

variable "bastion_name" {
  description = "Name of the Azure Bastion host"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with module common tags"
  type        = map(string)
  default     = {}
}
