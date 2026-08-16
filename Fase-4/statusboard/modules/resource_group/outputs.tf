output "name" {
  value       = azurerm_resource_group.this.name
  description = "Nome do Resource Group criado, usado pelos outros módulos"
}

output "location" {
  value       = azurerm_resource_group.this.location
  description = "Região do Resource Group, usada pelos outros módulos"
}

output "id" {
  value       = azurerm_resource_group.this.id
  description = "ID do Resource Group"
}