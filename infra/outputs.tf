output "resource_group_name" {
  description = "Nombre del resource group dev"
  value       = azurerm_resource_group.rg.name
}

output "aks_name" {
  description = "Nombre del cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config" {
  description = "Comando para obtener credenciales del AKS"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
