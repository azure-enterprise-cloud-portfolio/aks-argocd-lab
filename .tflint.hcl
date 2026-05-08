# =============================================================================
# TFLint Configuration
# Enables Azure-specific rules for the azurerm provider.
# =============================================================================
plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

config {
  # Scan all module calls recursively
  call_module_type = "all"
}