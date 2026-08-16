output "id" {
  value       = azurerm_container_registry.this.id
  description = "ID do ACR, usado para conceder permissão de pull ao Container App"
}

output "login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "Endereço do registry, usado para compor o nome completo da imagem"
}