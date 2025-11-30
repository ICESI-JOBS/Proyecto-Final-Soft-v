variable "prefix" {
  type        = string
  description = "Prefijo para el nombre del recurso"
}

variable "env" {
  type        = string
  description = "Entorno: dev, stage o prod"
}

variable "location" {
  type        = string
  description = "Región de Azure donde desplegar recursos"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Rango de direcciones de la VNet"
}

variable "subnet_aks_prefix" {
  type        = string
  description = "Rango de la subred para AKS"
}
