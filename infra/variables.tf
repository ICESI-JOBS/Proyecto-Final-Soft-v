variable "location" {
  description = "Región de Azure donde se desplegará la infraestructura"
  type        = string
  default     = "eastus" # o "southcentralus", "brazilsouth", etc.
}

variable "project_prefix" {
  description = "Prefijo para nombrar recursos"
  type        = string
  default     = "icesijobs"
}

variable "env" {
  description = "Nombre del entorno (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "aks_node_count" {
  description = "Número de nodos del pool del AKS"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "Tamaño de la VM de los nodos de AKS"
  type        = string
  default     = "Standard_B2s"
}
