locals {
  # Nombre base para recursos
  base_name = "${var.project_prefix}-${var.env}"
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${local.base_name}-rg"
  location = var.location
}

# 2. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.base_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_aks" {
  name                 = "${local.base_name}-subnet-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. Log Analytics Workspace (para monitoreo de AKS)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${local.base_name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 4. AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.base_name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${local.base_name}-dns"

  default_node_pool {
    name       = "systempool"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_vm_size

    vnet_subnet_id = azurerm_subnet.subnet_aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  # 👇 Aquí indicamos explícitamente la configuración de red del cluster,
  # con rangos que NO se cruzan con la VNet/Subnet.
  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"

    service_cidr       = "10.2.0.0/16"
    dns_service_ip     = "10.2.0.10"
  }

  role_based_access_control_enabled = true
  local_account_disabled            = false
}
