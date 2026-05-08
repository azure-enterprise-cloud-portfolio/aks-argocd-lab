# ============================================================
# Networking Module - Provider Version Locks
#
# Each module locks its own provider versions to prevent
# unexpected breaking changes when providers are updated.
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