output "resource_group_name" {
  value = module.network.resource_group_name
}

output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}
