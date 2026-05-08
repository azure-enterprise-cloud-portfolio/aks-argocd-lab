# ============================================================
# Dev Environment - Variables
#
# All values are passed via terraform.tfvars.
# Sensitive values (ssh_public_key) come from environment
# variables or CI/CD secrets — never hardcoded.
# ============================================================

variable "prefix" {
  description = "Short prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
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
  description = "List of Entra ID user object IDs to add to AKS Admin group"
  type        = list(string)
  default     = []
}

variable "dev_group_members" {
  description = "List of Entra ID user object IDs to add to AKS Developer group"
  type        = list(string)
  default     = []
}
variable "dev_subscription_id" {
  description = <<-EOT
    Azure subscription ID for dev workload resources.
    Injected via GitHub Actions secret: AZURE_DEV_SUBSCRIPTION_ID
  EOT
  type        = string
  sensitive   = true
}

