resource "azurerm_resource_group" "app-service-rg" {
 name = "${var.env}-${var.app}-rg" 
 location = var.location

 tags = {
   "environment" = var.env
 }
}

resource "azurerm_app_service_plan" "app-service-plan" {
  name = "${var.env}-${var.app}-plan"
  resource_group_name = azurerm_resource_group.app-service-rg.name
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
  resource_group_name = azurerm_resource_group.app-service-rg.name
  location = var.location

  site_config {
    linux_fx_version = "DOCKER|appsvcsample/static-site:latest"
    always_on        = "true"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
   "environment" = var.env
 }
}