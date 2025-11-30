terraform {
  backend "azurerm" {
    resource_group_name  = "icesijobs-tfstate-rg"
    storage_account_name = "icesijobstfstate"   # o el nombre que hayas usado
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
