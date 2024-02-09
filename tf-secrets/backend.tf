 locals {
  yaml= yamldecode(file("${path.module}/conf.yml"))
 }
 terraform {
    backend "azurerm" {
        resource_group_name = "rg-tf"
        storage_account_name = "tfsacruz3r"
        container_name = "tfappname1"
        key = "tfappname1"
    }
}