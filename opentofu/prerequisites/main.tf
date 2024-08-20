/**
* # Azure Storage Account and Container for Terraform State
* 
* This Terraform configuration creates an Azure Storage Account and Container to store Terraform state files. Additionally, it securely stores the secrets of the created resources in BitWarden.
* 
* ## Overview
* 
* * This module creates the following resources:
*   * Azure Storage Account
*   * Azure Storage Container
*   * BitWarden Organization Collection for storing Azure secrets
* 
* ## Requirements
* * Azure subscription with sufficient permissions to create Storage Accounts and Containers
* * BitWarden account with Organization setup
* 
* ## Important Notes
* 
* * After running this configuration, you should modify the backend configuration in [opentofu/prerequisites/providers.tf] to store the state in the newly created Azure Storage Account and Container.
* * To destroy the resources and keep the state files sane, you need to first set the state back to local by uncommenting the backend configuration in [opentofu/prerequisites/providers.tf] and initiating the migration by running `terraform init -migrate-state`.
*/

data "bitwarden_organization" "starfleet-organization" {
  search = var.bitwarden-organization
}

resource "bitwarden_org_collection" "azuresecrets" {
  name            = "AzureSecrets"
  organization_id = data.bitwarden_organization.starfleet-organization.id
}

data "azuread_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "azuread_application" "state-storage-service-principal" {
  display_name = "isonet-casa-terraform-state-storage"
  owners       = [data.azuread_client_config.current.object_id]
  web {
    homepage_url = "https://isonet-casa-terraform-state-storage-sp"
  }
}

resource "azuread_service_principal" "state-storage-service-principal" {
  owners    = [data.azuread_client_config.current.object_id]
  client_id = azuread_application.state-storage-service-principal.client_id
}

resource "azuread_service_principal_password" "state-storage-service-principal" {
  service_principal_id = azuread_service_principal.state-storage-service-principal.object_id
}

resource "bitwarden_item_login" "azure-state-storage-user" {
  name     = azuread_service_principal.state-storage-service-principal.display_name
  username = azuread_service_principal.state-storage-service-principal.client_id
  password = azuread_service_principal_password.state-storage-service-principal.value

  organization_id = data.bitwarden_organization.starfleet-organization.id
  collection_ids  = [bitwarden_org_collection.azuresecrets.id]

  field {
    name = "object_id"
    text = azuread_service_principal.state-storage-service-principal.object_id
  }

  field {
    name = "client_id"
    text = azuread_service_principal.state-storage-service-principal.client_id
  }

  field {
    name = "tenant_id"
    text = data.azuread_client_config.current.tenant_id
  }
}

resource "azurerm_resource_group" "starfleet-home-automation-rg" {
  name     = "starfleet-home-automation"
  location = "South Africa North"
}

resource "azurerm_storage_account" "starfleet-home-automation-storage" {
  name                            = "starfleethomeautomation"
  resource_group_name             = azurerm_resource_group.starfleet-home-automation-rg.name
  location                        = azurerm_resource_group.starfleet-home-automation-rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "starfleet-home-automation-state-storage-container" {
  name                  = var.azure-state-storage-container-name
  storage_account_name  = azurerm_storage_account.starfleet-home-automation-storage.name
  container_access_type = "private"
}


resource "bitwarden_item_login" "azure-state-storage-container-details" {
  name     = "${azurerm_storage_container.starfleet-home-automation-state-storage-container.name}-connection-details"
  username = ""
  password = ""

  organization_id = data.bitwarden_organization.starfleet-organization.id
  collection_ids  = [bitwarden_org_collection.azuresecrets.id]

  field {
    name = "id"
    text = azurerm_storage_container.starfleet-home-automation-state-storage-container.id
  }

  field {
    name = "resource_manager_id"
    text = azurerm_storage_container.starfleet-home-automation-state-storage-container.resource_manager_id
  }

  field {
    name = "storage_account_name"
    text = azurerm_storage_container.starfleet-home-automation-state-storage-container.storage_account_name
  }

  field {
    name = "storage_container_name"
    text = azurerm_storage_container.starfleet-home-automation-state-storage-container.name
  }

  field {
    name = "resource_group_name"
    text = azurerm_storage_account.starfleet-home-automation-storage.resource_group_name
  }

  field {
    name = "subscription_id"
    text = data.azurerm_subscription.current.id
  }

  field {
    name = "tenant_id"
    text = data.azuread_client_config.current.tenant_id
  }
}

resource "azurerm_role_assignment" "state-storage-service-principal-blod-owner" {
  principal_id         = azuread_service_principal.state-storage-service-principal.object_id
  role_definition_name = "Storage Blob Data Owner"
  scope                = azurerm_storage_container.starfleet-home-automation-state-storage-container.resource_manager_id
}
