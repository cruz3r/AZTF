 terraform {
    backend "azurerm" {
        storage_account_name = "stgcruz3rlr"
        container_name = "tfapistate"
        key = "tfapistate"
    }
}