terraform {
  required_version = "1.8.2"
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
    storage_account_name = var.azure-state-storage-account-name
    container_name       = var.azure-state-storage-container-name
    key                  = var.azure-state-storage-key
    use_azuread_auth     = true
    subscription_id      = var.azure-state-storage-subscription-id
    tenant_id            = var.azure-state-storage-tenant-id
    client_id            = var.azure-state-storage-client-id
    client_secret        = var.azure-state-storage-client-secret
  }
}

provider "azurerm" {
  features {}
  environment         = "Public"
  storage_use_azuread = true
  subscription_id     = var.azure-state-storage-subscription-id
}

provider "azuread" {

}

provider "bitwarden" {
  email           = var.bitwarden-email
  master_password = var.bitwarden-master-password
  client_id       = var.bitwarden-client-id
  client_secret   = var.bitwarden-client-secret
}

provider "unifi" {
  username       = data.bitwarden_item_login.unifi-credentials.username
  password       = data.bitwarden_item_login.unifi-credentials.password
  api_url        = var.unifi-api-url
  allow_insecure = var.unifi-insecure
}

provider "proxmox" {
  endpoint = data.bitwarden_item_login.proxmox-credentials.uri[0].value
  username = data.bitwarden_item_login.proxmox-credentials.username
  password = data.bitwarden_item_login.proxmox-credentials.password
  insecure = true
  tmp_dir  = "/var/tmp"
}