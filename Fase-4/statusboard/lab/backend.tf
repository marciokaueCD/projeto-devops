terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "=4.1.0"
        }
    }

  backend "azurerm" {
    use_cli              = true                                    
    use_azuread_auth     = true                                    
    tenant_id            = "9a7161ff-01fb-4d88-813d-cfc075a1d7bd"  
    storage_account_name = "tfstatestatusboard1"                              
    container_name       = "tfstate"                               
    key                  = "statusboard-lab.tfstate"    
}

}

provider "azurerm" {
  features {}
  subscription_id = "24f2d814-2f6a-422c-811c-8287d36f20ea"
  # evita que o provider varra e tente registrar TODOS os ~200 Resource
  # Providers da Azure a cada plan/apply — isso é o que estava deixando
  # o comando lento. "none" desativa a varredura automática; os providers
  # usados neste projeto (Resource Groups, ACR, Container Apps) já vêm
  # registrados por padrão em qualquer assinatura nova.
  #resource_provider_registrations = "none"
}