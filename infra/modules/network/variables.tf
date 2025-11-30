variable "env" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vnet_address_space" {
  description = "VNet CIDR"
  type        = list(string)
}

variable "subnet_aks_prefix" {
  description = "AKS subnet CIDR"
  type        = string
}
