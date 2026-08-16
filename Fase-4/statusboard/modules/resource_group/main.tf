resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}