terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
  required_version = "~> 1.11"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "random" {
  # Configure the random provider
  # This provider is used to generate a random string for the storage account name
}

provider "azapi" {
  # Configure the azapi provider
  # This provider is used to create the image builder template
  enable_preflight = false
  subscription_id  = var.subscription_id
}
