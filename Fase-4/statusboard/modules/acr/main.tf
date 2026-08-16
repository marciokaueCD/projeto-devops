resource "azurerm_container_registry" "this" {
  name                = "acr${var.project}${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false 

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}