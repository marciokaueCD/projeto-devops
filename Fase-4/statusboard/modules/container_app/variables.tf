variable "project" {
  type        = string
  description = "Nome do projeto, usado como prefixo dos recursos"
}

variable "environment" {
  type        = string
  description = "Ambiente de deploy (dev, staging, lab, prod)"
}

variable "resource_group_name" {
  type        = string
  description = "Nome do Resource Group (vem do módulo resource_group)"
}

variable "location" {
  type        = string
  description = "Região do Azure (vem do módulo resource_group)"
}

variable "acr_id" {
  type        = string
  description = "ID do ACR, usado para conceder a permissão AcrPull (vem do módulo acr)"
}

variable "acr_login_server" {
  type        = string
  description = "Endereço do ACR (vem do módulo acr)"
}

variable "container_image" {
  type        = string
  description = "Imagem completa a ser executada, ex: acrstatusboardprod.azurecr.io/statusboard:v1.0"
}

variable "container_cpu" {
  type        = number
  description = "vCPU alocado ao container"
  default     = 0.25
}

variable "container_memory" {
  type        = string
  description = "Memória alocada ao container"
  default     = "0.5Gi"
}

variable "min_replicas" {
  type        = number
  description = "Número mínimo de réplicas (0 permite scale-to-zero)"
  default     = 0
}

variable "max_replicas" {
  type        = number
  description = "Número máximo de réplicas, evita custo descontrolado em picos de tráfego"
  default     = 2
}
