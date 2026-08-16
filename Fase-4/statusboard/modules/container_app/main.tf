resource "azurerm_container_app_environment" "this" {
  name                = "env-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

# identidade criada de forma independente do Container App — isso é o que
# resolve a dependência circular: a permissão de AcrPull pode ser concedida
# a essa identidade ANTES do Container App existir, evitando que ele tente
# puxar a imagem sem permissão (o que causava o "Operation expired").
resource "azurerm_user_assigned_identity" "this" {
  name                = "id-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

# permissão concedida à identidade sozinha, sem depender do Container App existir
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id          = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_container_app" "this" {
  name                         = "${var.project}-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"

  # depends_on explícito: garante que o Terraform só tenta criar o Container App
  # depois que a permissão AcrPull já foi concedida de verdade, não só "solicitada"
  depends_on = [azurerm_role_assignment.acr_pull]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  template {
    container {
      name   = var.project
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  ingress {
    external_enabled = true
    target_port       = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server   = var.acr_login_server
    identity = azurerm_user_assigned_identity.this.id
  }

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}