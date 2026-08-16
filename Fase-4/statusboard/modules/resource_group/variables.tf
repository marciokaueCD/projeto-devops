variable "project" {
  type        = string
  description = "Nome do projeto, usado como prefixo dos recursos"
}

variable "environment" {
  type        = string
  description = "Ambiente de deploy (dev, staging, prod, lab)"

  validation {
    condition     = contains(["dev", "staging", "prod", "lab"], var.environment)
    error_message = "O ambiente deve ser dev, staging, lab ou prod."
  }
}

variable "location" {
  type        = string
  description = "Região do Azure onde os recursos serão criados"
  default     = "East US"
}