resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-${var.env}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.prefix}-${var.env}-aks"

  default_node_pool {
    name       = "systempool"
    node_count = var.node_count
    vm_size    = var.vm_size
    # el resto igual…
}

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.2.0.0/16"
    dns_service_ip     = "10.2.0.10"
  }
}
