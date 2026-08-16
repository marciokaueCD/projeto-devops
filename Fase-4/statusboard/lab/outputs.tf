output "app_url" {
  value       = module.container_app.url
  description = "URL pública do StatusBoard em produção"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "Endereço do ACR, usado no docker push/login"
}
