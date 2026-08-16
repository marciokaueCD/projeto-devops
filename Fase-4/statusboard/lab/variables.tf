variable "project" {
  type        = string
  description = "Nome do projeto, usado como prefixo dos recursos"
  default     = "statusboard"
}

variable "environment" {
  type        = string
  description = "Ambiente de deploy"
  default     = "lab"

  validation {
    condition     = contains(["dev", "staging", "lab", "prod"], var.environment)
    error_message = "O ambiente deve ser dev, staging, lab ou prod."
  }
}

variable "location" {
  type        = string
  description = "Região do Azure"
  default     = "East US 2"
}

variable "acr_sku" {
  type        = string
  description = "Tier do ACR"
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "O SKU deve ser Basic, Standard ou Premium."
  }
}

variable "container_image" {
  type        = string
  description = "Imagem completa a ser executada (registry + repositório + tag)"
}

variable "min_replicas" {
  type        = number
  description = "Réplicas mínimas do Container App"
  default     = 1 
}

variable "max_replicas" {
  type        = number
  description = "Réplicas máximas do Container App"
  default     = 2
}
