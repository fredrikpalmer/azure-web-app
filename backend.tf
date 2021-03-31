terraform {
  backend "azurerm" {
    resource_group_name = "fredrikpalmer-dev"
    storage_account_name = "fredrikpalmer"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}