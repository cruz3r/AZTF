locals {
  yaml= yamldecode(file("${path.module}/conf.yml"))
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = local.yaml.location
}