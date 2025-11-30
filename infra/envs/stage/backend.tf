terraform {
  backend "azurerm" {
    resource_group_name  = "icesijobs-tfstate-rg"
    storage_account_name = "icesijobstfstate"
    container_name       = "tfstate"
    key                  = "stage.terraform.tfstate"
  }
}
