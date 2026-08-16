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
    tenant_id            = "7185686c-e569-4a0f-b10b-0c839bbd4d8c"  
    storage_account_name = "tfstatestatusboard"                              
    container_name       = "tfstate"                               
    key                  = "statusboard-lab.tfstate"    
}

}

provider "azurerm" {
  features {}
  subscription_id = "7c1f98e6-7985-41db-98cb-c2218c2fc145"
  # evita que o provider varra e tente registrar TODOS os ~200 Resource
  # Providers da Azure a cada plan/apply — isso é o que estava deixando
  # o comando lento. "none" desativa a varredura automática; os providers
  # usados neste projeto (Resource Groups, ACR, Container Apps) já vêm
  # registrados por padrão em qualquer assinatura nova.
  resource_provider_registrations = "none"
}