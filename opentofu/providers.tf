terraform {
  required_version = "1.9.0"
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
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.41.2"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.63.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
  backend "azurerm" {
    storage_account_name = var.azure_state_storage_account_name
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
  client_id           = var.terraform_sp_client_id
  client_secret       = var.terraform_sp_client_secret
  tenant_id           = var.azure_state_storage_tenant_id
}

provider "azuread" {

}

provider "bitwarden" {
  email           = var.bitwarden_email
  master_password = var.bitwarden_master_password
  client_id       = var.bitwarden_client_id
  client_secret   = var.bitwarden_client_secret
}

provider "unifi" {
  username       = data.bitwarden_item_login.unifi_credentials.username
  password       = data.bitwarden_item_login.unifi_credentials.password
  api_url        = var.unifi_api_url
  allow_insecure = var.unifi_insecure
}

provider "proxmox" {
  endpoint = data.bitwarden_item_login.proxmox_credentials.uri[0].value
  username = data.bitwarden_item_login.proxmox_credentials.username
  password = data.bitwarden_item_login.proxmox_credentials.password
  insecure = true
  tmp_dir  = "/var/tmp"
}