variable "prefix" {
  type = string
}

variable "env" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_aks_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "node_count" {
  type    = number
  default = 1
}
