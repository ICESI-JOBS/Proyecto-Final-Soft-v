terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # De momento usamos backend local.
  # Más adelante lo cambiamos a Azure Storage (backend remoto).
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "edd8230a-78c6-4b69-88b7-a25867975228"
  tenant_id       = "e994072b-523e-4bfe-86e2-442c5e10b244"
  # Terraform usará tu sesión actual de 'az login'
}
