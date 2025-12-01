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
  description = "Resource group donde se creará AKS"
}

variable "subnet_aks_id" {
  type        = string
  description = "ID de la subred donde se montará AKS"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del workspace para monitoring"
}

variable "node_count" {
  type        = number
  description = "Número de nodos para el cluster"
}

variable "vm_size" {
  type        = string
  description = "SKU de la VM para el node pool de AKS"
}