data "azurerm_client_config" "current" {}

data "azuread_group" "developers" {
  display_name = "Developers"
}

locals {
  name = "${var.org}-${var.business_area}-${var.domain}-${var.context}"
  tags = {
    "organization"  = var.org
    "team"          = var.team
    "business_area" = var.business_area
    "domain"        = var.domain
    "context"       = var.context
    "environment"   = var.env
  }
}

resource "azurerm_resource_group" "app_rg" {
  name     = "${local.name}-rg"
  location = var.location

  tags = local.tags
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "${local.name}-plan"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "S1"

  tags = local.tags
}

resource "azurerm_linux_web_app" "app_service" {
  name                = "${local.name}-service"
  service_plan_id     = azurerm_service_plan.app_service_plan.id
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = var.location

  site_config {
    application_stack {
      docker_image     = "DOCKER|${azurerm_container_registry.app_container_registry.login_server}/${var.domain}-${var.context}:latest"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    Secret                          = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.app_key_vault.vault_uri}secrets/${azurerm_key_vault_secret.app_key_vault_secret.name}/${azurerm_key_vault_secret.app_key_vault_secret.version})"
    DOCKER_REGISTRY_SERVER_URL      = "https://${azurerm_container_registry.app_container_registry.login_server}"
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
  name                = "${local.name}-kv"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  tags = local.tags
}

resource "azurerm_key_vault_access_policy" "app_key_vault_access_policy" {
  key_vault_id       = azurerm_key_vault.app_key_vault.id
  object_id          = azurerm_linux_web_app.app_service.identity[0].principal_id
  tenant_id          = azurerm_linux_web_app.app_service.identity[0].tenant_id
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "app_key_vault_access_policy_terraform" {
  key_vault_id       = azurerm_key_vault.app_key_vault.id
  object_id          = data.azurerm_client_config.current.object_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  secret_permissions = ["Delete", "Get", "Set", "Purge"]
}

resource "azurerm_key_vault_access_policy" "app_key_vault-access_policy_developers" {
  key_vault_id       = azurerm_key_vault.app_key_vault.id
  object_id          = data.azuread_group.developers.object_id
  tenant_id          = azurerm_linux_web_app.app_service.identity[0].tenant_id
  secret_permissions = ["Delete", "Get", "Set", "Purge", "List"]
}

resource "azurerm_key_vault_secret" "app_key_vault_secret" {
  name         = "${local.name}-kv-secret"
  key_vault_id = azurerm_key_vault.app_key_vault.id
  value        = "secret"
  depends_on   = [azurerm_key_vault_access_policy.app_key_vault_access_policy_terraform]

  tags = local.tags

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "azurerm_container_registry" "app_container_registry" {
  name                = "${var.org}${var.business_area}"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = local.tags
}

resource "azurerm_role_assignment" "app_role_assigment_acrpull" {
  principal_id         = azurerm_linux_web_app.app_service.identity[0].principal_id
  scope                = azurerm_container_registry.app_container_registry.id
  role_definition_name = "AcrPull"
}
