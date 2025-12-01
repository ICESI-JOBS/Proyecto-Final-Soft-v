variable "prefix" {
  type        = string
  description = "Prefijo común para nombrar los recursos"
  default     = "icesijobs"
}

variable "env" {
  type        = string
  description = "Nombre del entorno (dev, stage o prod)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Región donde se desplegarán los recursos"
  default     = "eastus"
}

variable "node_count" {
  type        = number
  description = "Número de nodos del cluster AKS"
  default     = 1
}

variable "vm_size" {
  type        = string
  description = "Tamaño de las VMs del node pool de AKS"
  default     = "Standard_B2s"
}
