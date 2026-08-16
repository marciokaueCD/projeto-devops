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
  description = "Nome do Resource Group onde o ACR será criado (vem do módulo resource_group)"
}

variable "location" {
  type        = string
  description = "Região do Azure (vem do módulo resource_group)"
}

variable "sku" {
  type        = string
  description = "Tier do ACR (Basic, Standard, Premium)"
  default     = "Basic"
}