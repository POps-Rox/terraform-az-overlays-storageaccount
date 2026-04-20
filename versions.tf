terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    popsrox-utils = {
      source  = "POps-Rox/popsrox-utils"
      version = "~> 1.0.4"
    }
  }
}