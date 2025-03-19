terraform {
  required_version = "1.11.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0.0"
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
  backend "azurerm" {
    storage_account_name = var.azure_general_storage_account_name
    container_name       = var.azure_state_storage_container_name
    key                  = var.azure_state_storage_key
    use_azuread_auth     = true
    subscription_id      = var.azure_state_storage_subscription_id
    tenant_id            = var.azure_state_storage_tenant_id
    client_id            = var.azure_state_storage_client_id
    client_secret        = var.azure_state_storage_client_secret
  }
}

provider "azurerm" {
  features {}
  environment         = "Public"
  storage_use_azuread = true
  subscription_id     = var.azure_state_storage_subscription_id
  # Comment these out until the service principal is created
  client_id     = var.terraform_sp_client_id
  client_secret = var.terraform_sp_client_secret
  tenant_id     = var.azure_state_storage_tenant_id
}

provider "azuread" {

}

provider "bitwarden" {
  email           = var.bitwarden_email
  master_password = var.bitwarden_master_password
  client_id       = var.bitwarden_client_id
  client_secret   = var.bitwarden_client_secret
}
