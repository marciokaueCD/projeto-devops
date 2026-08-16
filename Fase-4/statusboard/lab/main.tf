module "resource_group" {
  source = "../modules/resource_group"

  project     = var.project
  environment = var.environment
  location    = var.location
}

module "acr" {
  source = "../modules/acr"

  project              = var.project
  environment          = var.environment
  resource_group_name = module.resource_group.name
  location             = module.resource_group.location
  sku                   = var.acr_sku
}

module "container_app" {
  source = "../modules/container_app"

  project              = var.project
  environment          = var.environment
  resource_group_name = module.resource_group.name
  location             = module.resource_group.location
  acr_id                = module.acr.id
  acr_login_server     = module.acr.login_server
  container_image      = var.container_image

  min_replicas = var.min_replicas
  max_replicas = var.max_replicas
}
