terraform {
  required_version = "1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53.0"
    }
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
