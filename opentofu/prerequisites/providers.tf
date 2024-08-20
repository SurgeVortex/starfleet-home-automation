terraform {
  required_version = "1.9.5"
  required_providers {
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "~> 3.116.0"
    # }
    # azuread = {
    #   source  = "hashicorp/azuread"
    #   version = "~> 2.53.0"
    # }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "~> 0.8.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

# provider "azurerm" {
#   features {}
# }

# provider "azuread" {

# }

provider "bitwarden" {
  email           = var.bitwarden-email
  master_password = var.bitwarden-master-password
  client_id       = var.bitwarden-client-id
  client_secret   = var.bitwarden-client-secret
}