terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.54.0"
    }
  }
}

provider "azurerm" {
  features {}
  # tu suscripción de Azure for Students
  subscription_id = "edd8230a-78c6-4b69-88b7-a25867975228"
}

module "network" {
  source             = "../../modules/network"
  prefix             = var.prefix
  env                = var.env
  location           = var.location
  vnet_address_space = ["10.0.0.0/16"]
  subnet_aks_prefix  = "10.0.1.0/24"
}

module "monitoring" {
  source              = "../../modules/monitoring"
  prefix              = var.prefix
  env                 = var.env
  location            = var.location
  resource_group_name = module.network.resource_group_name
}

module "aks" {
  source                     = "../../modules/aks"
  prefix                     = var.prefix
  env                        = var.env
  location                   = var.location
  resource_group_name        = module.network.resource_group_name
  subnet_aks_id              = module.network.subnet_aks_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  node_count                 = var.node_count
  vm_size                    = var.vm_size
}
