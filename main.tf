data "azurerm_client_config" "current" {}

data "azuread_group" "developers" {
  display_name = "Developers"
}

locals {
  name = "${var.org}-${var.domain}-${var.app}-${var.context}"
  tags = {
    "organization" = var.org
    "team" = var.team
    "domain" = var.domain
    "context" = var.context
    "environment" = var.env
  }
}

resource "azurerm_resource_group" "app_rg" {
 name = "${local.name}-rg" 
 location = var.location

 tags = local.tags
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name = "${local.name}-plan"
  resource_group_name = azurerm_resource_group.app_rg.name
  location = var.location
  kind = "Linux"
  reserved = true

  sku {
    size = "S1"
    tier = "standard"
  }
  
  tags = local.tags
}

resource "azurerm_app_service" "app_service" {
  name = "${local.name}-service"
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  resource_group_name = azurerm_resource_group.app_rg.name
  location = var.location

  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.app_container_registry.login_server}/${var.app}-${var.context}:latest"
    always_on        = "true"
  }

  app_settings = {    
    Secret = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.app_key_vault.vault_uri}secrets/${azurerm_key_vault_secret.app_key_vault_secret.name}/${azurerm_key_vault_secret.app_key_vault_secret.version})"
    DOCKER_REGISTRY_SERVER_URL = "https://${azurerm_container_registry.app_container_registry.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.app_container_registry.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.app_container_registry.admin_password
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags

 lifecycle {
   ignore_changes = [
    app_settings
   ]
 }
}

resource "azurerm_key_vault" "app_key_vault" {
  name = "${local.name}-kv"
  resource_group_name = azurerm_resource_group.app_rg.name
  location = var.location
  tenant_id = var.tenant_id
  sku_name = "standard"

  tags = local.tags
}

resource "azurerm_key_vault_access_policy" "app_key_vault_access_policy" {
  key_vault_id = azurerm_key_vault.app_key_vault.id
  object_id = azurerm_app_service.app_service.identity[0].principal_id
  tenant_id = azurerm_app_service.app_service.identity[0].tenant_id
  secret_permissions = [ "get", "list" ]
}

resource "azurerm_key_vault_access_policy" "app_key_vault_access_policy_terraform" {
  key_vault_id = azurerm_key_vault.app_key_vault.id
  object_id = data.azurerm_client_config.current.object_id
  tenant_id = data.azurerm_client_config.current.tenant_id
  secret_permissions = [ "delete", "get", "set", "purge" ]
}

resource "azurerm_key_vault_access_policy" "app_key_vault-access_policy_developers" {
  key_vault_id = azurerm_key_vault.app_key_vault.id
  object_id = data.azuread_group.developers.object_id
  tenant_id = azurerm_app_service.app_service.identity[0].tenant_id
  secret_permissions = [ "delete", "get", "set", "purge", "list" ]
}

resource "azurerm_key_vault_secret" "app_key_vault_secret" {
  name = "${local.name}-kv-secret"
  key_vault_id = azurerm_key_vault.app_key_vault.id
  value = "secret"
  depends_on = [azurerm_key_vault_access_policy.app_key_vault_access_policy_terraform]

  tags = local.tags

 lifecycle {
   ignore_changes = [
     value
   ]
 }
}

resource "azurerm_container_registry" "app_container_registry" {
  name = "${var.org}${var.domain}"
  resource_group_name = azurerm_resource_group.app_rg.name
  location = var.location
  sku = "Standard"
  admin_enabled = true

  tags = local.tags
}

resource "azurerm_role_assignment" "app_role_assigment_acrpull" {
  principal_id = azurerm_app_service.app_service.identity[0].principal_id
  scope = azurerm_container_registry.app_container_registry.id
  role_definition_name = "AcrPull"
}