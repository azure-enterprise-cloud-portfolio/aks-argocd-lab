# ============================================================
# AKS Module - Provider Version Locks
#
# Locks azurerm provider version to prevent breaking changes.
# AKS resources are sensitive to provider version changes
# as the AKS API evolves frequently.
# ============================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}