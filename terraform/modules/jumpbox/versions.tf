# ============================================================
# Jumpbox Module - Provider Version Locks
#
# Locks azurerm provider to prevent breaking changes.
# VM resources are stable but provider updates can affect
# custom_data handling and VM extension behaviour.
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