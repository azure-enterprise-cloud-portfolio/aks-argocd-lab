# =============================================================================
# Dev Environment — Terraform & Provider Configuration
#
# - Backend stores dev state in cs-platform-shared storage account
# - Two provider aliases: dev (workload) and platform (shared services)
# - Subscription IDs injected via TF_VAR_* from GitHub Actions secrets
# - OIDC authentication used throughout — no client secrets stored anywhere
# =============================================================================

terraform {
  required_version = "~> 1.14.0"

  # =============================================================================
  # Remote State Backend — Platform Subscription
  #
  # State lives in cs-platform-shared, NOT in the dev subscription.
  # Single storage account holds state for all environments in separate keys.
  #
  # State key structure:
  #   platform/terraform.tfstate          ← shared services
  #   workload/dev/terraform.tfstate      ← this file
  #   workload/prod/terraform.tfstate     ← prod (future)
  # =============================================================================
  backend "azurerm" {
    resource_group_name  = "rg-cs-tfstate-cac"
    storage_account_name = "stcstfstatecac001"
    container_name       = "tfstate"
    key                  = "workload/dev/terraform.tfstate"
    use_oidc             = true # OIDC auth — no storage access keys needed
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Allows 4.x minor/patch, blocks 5.x breaking changes
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0" # Aligns with azurerm 4.x
    }
  }
}

# =============================================================================
# Provider: Dev Subscription (cs-workload-dev)
# Subscription ID: a894498f-a0c7-4ef2-8aca-e159bd5b8604
#
# Deploys all dev workload resources:
#   - Resource Group
#   - VNet + Subnets + Bastion + NSGs
#   - AKS Cluster + ACR + Key Vault + Log Analytics
#   - Jumpbox VM
# =============================================================================
provider "azurerm" {
  alias           = "dev"
  subscription_id = var.dev_subscription_id
  use_oidc        = true

  features {
    key_vault {
      # Allow purge on destroy — safe for lab cleanup
      # Set to false in prod to prevent accidental secret loss
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      # Allow destroy even if RG contains resources
      # Useful for clean lab teardown
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =============================================================================
# Provider: Platform Subscription (cs-platform-shared)
# Subscription ID: 0f6c7caf-02c3-42b0-9ac6-38675a112685
#
# Currently used for:
#   - Remote state backend (handled automatically above)
#   - Future: shared ACR, hub VNet peering, DNS zones
# =============================================================================
#
# Used for:
#   - Creating AKS Admin + Developer Entra ID groups
#   - Looking up user object IDs dynamically
#   - Avoiding hardcoded Object IDs in code
#
# Ensure the pipeline Service Principal has:
#   - Directory.Read.All or Group.Read.All in Entra ID
# =============================================================================
provider "azuread" {
  use_oidc = true
}