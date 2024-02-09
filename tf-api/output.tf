output "az-rg" {
  value = [azurerm_resource_group.example.name, azurerm_resource_group.example.id]
}