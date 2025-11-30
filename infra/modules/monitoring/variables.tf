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

variable "resource_group_name" {
  type        = string
  description = "Nombre del resource group donde se crea Log Analytics"
}
