data "azurerm_client_config" "current" {
  
}

resource "azurerm_resource_group" "app-rg" {
 name = "${var.env}-${var.app}-rg" 
 location = var.location

 tags = {
   "environment" = var.env
 }
}

resource "azurerm_app_service_plan" "app-service-plan" {
  name = "${var.env}-${var.app}-plan"
  resource_group_name = azurerm_resource_group.app-rg.name
  location = var.location
  kind = "Linux"
  reserved = true

  sku {
    size = "S1"
    tier = "standard"
  }
  
  tags = {
   "environment" = var.env
 }
}

resource "azurerm_app_service" "app-service" {
  name = "${var.env}-${var.app}-service"
  app_service_plan_id = azurerm_app_service_plan.app-service-plan.id
  resource_group_name = azurerm_resource_group.app-rg.name
  location = var.location

  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.app-container-registry.login_server}/${var.app}:latest"
    always_on        = "true"
  }

  app_settings = {    
    Secret = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.app-key-vault.vault_uri}secrets/${azurerm_key_vault_secret.app-key-vault-secret.name}/${azurerm_key_vault_secret.app-key-vault-secret.version})"    
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
   "environment" = var.env
 }
}

resource "azurerm_key_vault" "app-key-vault" {
  name = "${var.env}-${var.app}-kv"
  resource_group_name = azurerm_resource_group.app-rg.name
  location = var.location
  tenant_id = var.tenant_id
  sku_name = "standard"

  tags = {
   "environment" = var.env
 }
}

resource "azurerm_key_vault_access_policy" "app-key-vault-access-policy-terraform" {
  key_vault_id = azurerm_key_vault.app-key-vault.id
  object_id = data.azurerm_client_config.current.object_id
  tenant_id = data.azurerm_client_config.current.tenant_id
  secret_permissions = [ "delete", "get", "set", "purge" ]
}

resource "azurerm_key_vault_access_policy" "app-key-vault-access-policy-application" {
  key_vault_id = azurerm_key_vault.app-key-vault.id
  object_id = azurerm_app_service.app-service.identity[0].principal_id
  tenant_id = azurerm_app_service.app-service.identity[0].tenant_id
  secret_permissions = [ "get", "list" ]
}

resource "azurerm_key_vault_secret" "app-key-vault-secret" {
  name = "${var.env}-${var.app}-kv-secret"
  key_vault_id = azurerm_key_vault.app-key-vault.id
  value = "secret"
  depends_on = [azurerm_key_vault_access_policy.app-key-vault-access-policy-terraform]

  tags = {
   "environment" = var.env
 }
}

resource "azurerm_container_registry" "app-container-registry" {
  name = "${var.app}acr${var.env}"
  resource_group_name = azurerm_resource_group.app-rg.name
  location = var.location
  sku = "Standard"
  admin_enabled = true
}

resource "azurerm_role_assignment" "app-role-assigment-acrpull" {
  principal_id = azurerm_app_service.app-service.identity[0].principal_id
  scope = azurerm_container_registry.app-container-registry.id
  role_definition_name = "AcrPull"
}