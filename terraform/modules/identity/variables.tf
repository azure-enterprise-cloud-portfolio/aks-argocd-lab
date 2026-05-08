# ============================================================
# Identity Module - Variables
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
  description = "Azure region for the Managed Identity resource"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the Managed Identity will be created"
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

variable "admin_group_members" {
  description = <<-EOT
    List of Entra ID user object IDs to add to the AKS Admin group.
    Get your object ID: az ad signed-in-user show --query id -o tsv
  EOT
  type        = list(string)
  default     = []
}

variable "dev_group_members" {
  description = "List of Entra ID user object IDs to add to the AKS Developers group."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with module common tags"
  type        = map(string)
  default     = {}
}