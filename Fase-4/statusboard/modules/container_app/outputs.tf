output "url" {
  value       = "https://${azurerm_container_app.this.ingress[0].fqdn}"
  description = "URL pública onde a aplicação fica acessível"
}
