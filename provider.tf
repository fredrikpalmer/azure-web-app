provider "azurerm" {
  subscription_id = var.sub
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  features {
  }
}

provider "azuread" {}