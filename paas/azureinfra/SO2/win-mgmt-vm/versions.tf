terraform {
  backend "azurerm" {
    resource_group_name  = ""
    storage_account_name = ""
    container_name       = "terraform-backend"
    key                  = ""
    access_key           = ""
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.7.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "azurerm" {
  # Default
  subscription_id = var.infra_sub_id
  features {}
}
provider "azurerm" {
  # Management / Shared Services
  alias           = "images"
  subscription_id = var.images_sub_id
  features {}
}

provider "azurerm" {
  # Infrasturcture / Spoke
  alias           = "infra"
  subscription_id = var.infra_sub_id
  features {}
}

provider "azurerm" {
  # Infrasturcture / Spoke
  alias           = "mgmt"
  subscription_id = var.infra_sub_id
  features {}
}

