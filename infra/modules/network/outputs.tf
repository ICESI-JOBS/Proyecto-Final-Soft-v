output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.rg.location
}

output "subnet_aks_id" {
  value = azurerm_subnet.subnet_aks.id
}
