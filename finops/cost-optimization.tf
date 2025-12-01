# FinOps Configuration - Cost Optimization Policies
# Implementa Spot Instances, Auto-scaling y Cost Control

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

variable "environment" {
  default = "dev"
}

variable "project_name" {
  default = "ecommerce-app"
}

variable "location" {
  default = "eastus"
}

variable "monthly_budget_usd" {
  default = 1000
}

variable "enable_spot_instances" {
  default = true
}

variable "enable_auto_scaling" {
  default = true
}

# VMSS con Spot Instances para ahorro de costos
resource "azurerm_linux_virtual_machine_scale_set" "spot_vmss" {
  count = var.enable_spot_instances ? 1 : 0
  
  name                = "${var.project_name}-spot-vmss"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  
  sku           = "Standard_B2s"
  instances     = 2
  admin_username = "azureuser"

  # Enable Spot Instances (70% discount)
  priority        = "Spot"
  eviction_policy = "Deallocate"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.project_name}-nic"
    primary = true

    ip_configuration {
      name      = "testConfiguration"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }

  tags = {
    environment = var.environment
    project     = var.project_name
    cost_type   = "spot_instance"
  }
}

# AKS Cluster con Cost Optimization
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.project_name}-aks-cluster"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.project_name}-aks"

  default_node_pool {
    name                = "default"
    node_count          = 3
    vm_size             = "Standard_B2s"
    os_disk_size_gb     = 30
    
    # Enable Auto-scaling
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = 2
    max_count           = 5
    
    # Spot instances para nodos
    priority            = var.enable_spot_instances ? "Spot" : "Regular"
    eviction_policy     = var.enable_spot_instances ? "Delete" : null

    tags = {
      environment = var.environment
      cost_type   = var.enable_spot_instances ? "spot" : "regular"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Auto Scaling Rules para Kubernetes
resource "azurerm_kubernetes_cluster_node_pool" "spot_pool" {
  count = var.enable_spot_instances ? 1 : 0
  
  name                  = "spotpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = "Standard_B2s"
  node_count            = 2
  
  # Auto-scaling configuration
  enable_auto_scaling = var.enable_auto_scaling
  min_count           = 1
  max_count           = 3
  
  # Spot instances
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = 0.05 # Máximo que pagaremos por la instancia Spot

  tags = {
    environment = var.environment
    pool_type   = "spot"
    cost_optimized = true
  }
}

# Consumer Group para monitoreo de costos
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Virtual Network para suportar los recursos
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Outputs
output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks_cluster.id
}

output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true
}

output "spot_vmss_id" {
  value = var.enable_spot_instances ? azurerm_linux_virtual_machine_scale_set.spot_vmss[0].id : null
}
