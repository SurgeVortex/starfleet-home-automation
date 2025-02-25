resource "azuread_application" "longhorn_backup_service_principal" {
  display_name = var.azure_application_longhorn_backup_display_name
  owners       = [data.azuread_client_config.current.object_id]
  web {
    homepage_url = "https://${var.azure_application_longhorn_backup_display_name}-sp"
  }
}

resource "azuread_service_principal" "longhorn_backup_service_principal" {
  owners    = [data.azuread_client_config.current.object_id]
  client_id = azuread_application.longhorn_backup_service_principal.client_id
}

resource "azuread_service_principal_password" "longhorn_backup_service_principal" {
  service_principal_id = azuread_service_principal.longhorn_backup_service_principal.object_id
}

resource "bitwarden_item_login" "azure_longhorn_backup_user" {
  name     = azuread_service_principal.longhorn_backup_service_principal.display_name
  username = azuread_service_principal.longhorn_backup_service_principal.client_id
  password = azuread_service_principal_password.longhorn_backup_service_principal.value

  organization_id = data.bitwarden_organization.starfleet_organization.id
  collection_ids  = [bitwarden_org_collection.azuresecrets.id]

  field {
    name = "object_id"
    text = azuread_service_principal.longhorn_backup_service_principal.object_id
  }

  field {
    name = "client_id"
    text = azuread_service_principal.longhorn_backup_service_principal.client_id
  }

  field {
    name = "tenant_id"
    text = data.azuread_client_config.current.tenant_id
  }
}

resource "azurerm_storage_container" "starfleet_home_automation_longhorn_backup_container" {
  name                  = var.azure_longhorn_backup_container_name
  storage_account_name  = var.azure_state_storage_account_name
  container_access_type = "private"
}

resource "bitwarden_item_login" "azure_longhorn_backup_container_details" {
  name     = "${azurerm_storage_container.starfleet_home_automation_longhorn_backup_container.name}-connection-details"
  username = ""
  password = ""

  organization_id = data.bitwarden_organization.starfleet_organization.id
  collection_ids  = [bitwarden_org_collection.azuresecrets.id]

  field {
    name = "id"
    text = azurerm_storage_container.starfleet_home_automation_longhorn_backup_container.id
  }

  field {
    name = "resource_manager_id"
    text = azurerm_storage_container.starfleet_home_automation_longhorn_backup_container.resource_manager_id
  }

  field {
    name = "storage_account_name"
    text = azurerm_storage_container.starfleet_home_automation_longhorn_backup_container.storage_account_name
  }

  field {
    name = "storage_container_name"
    text = azurerm_storage_container.starfleet_home_automation_longhorn_backup_container.name
  }

  field {
    name = "resource_group_name"
    text = azurerm_storage_account.starfleet_home_automation_storage.resource_group_name
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

resource "azurerm_role_assignment" "longhorn_backup_access_blob_owner" {
  principal_id         = azuread_service_principal.longhorn_backup_service_principal.object_id
  role_definition_name = "Storage Blob Data Owner"
  scope                = azurerm_storage_container.starfleet_home_automation_longhorn_backup_container.resource_manager_id
}
