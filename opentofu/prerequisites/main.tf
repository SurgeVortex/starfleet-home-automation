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
* 
* ## Initial Setup Instructions
* 
* ### Prerequisites
* 
* * An Azure account with sufficient permissions to create resources.
* * A BitWarden account with an Organization setup.
* 
* ### Steps
* 
* 1. **Clone the Repository**
* 
*    ```sh
*    git clone https://github.com/your-repo/starfleet-home-automation.git
*    cd starfleet-home-automation/opentofu/prerequisites
*    ```
* 
* 2. **Configure Azure CLI**
* 
*    Ensure you are logged into your Azure account:
* 
*    ```sh
*    az login
*    ```
* 
* 3. **Obtain Required Variables**
* 
* You will need the following information to populate the `terraform.tfvars` file:
* 
* * `bitwarden_email`: Your BitWarden account email.
* * `bitwarden_master_password`: Your BitWarden master password.
* * `bitwarden_client_id`: Your BitWarden client ID.
* * `bitwarden_client_secret`: Your BitWarden client secret.
* * `azure_state_storage_account_name`: The name for the Azure Storage Account.
* * `azure_state_storage_container_name`: The name for the Azure Storage Container.
* * `azure_state_storage_key`: The key for the state storage.
* * `azure_state_storage_subscription_id`: Your Azure subscription ID.
* * `azure_state_storage_tenant_id`: Your Azure tenant ID.
* * `azure_state_storage_client_id`: Your Azure client ID.
* * `azure_state_storage_client_secret`: Your Azure client secret.
* 
* These values can be obtained from your Azure and BitWarden accounts.
* 
* #### How to Obtain These Values:
* 
* - **BitWarden Client ID and Secret:**
*   1. Log in to your BitWarden account.
*   2. Navigate to the "Settings" page.
*   3. Under "API Key", generate a new client ID and secret.
* 
* - **Azure Subscription ID and Tenant ID:**
*   1. Log in to the Azure portal.
*   2. Navigate to "Subscriptions".
*   3. Select the subscription you want to use.
*   4. The subscription ID and tenant ID will be displayed on the overview page.
*   5.  Alternatively, you can use the Azure CLI:
* 
* ```sh
* az account show --query "{subscriptionId:id, tenantId:tenantId}"
* ```
* 
* - **Azure Client ID and Secret:**
* This will be gotten after the initial run with the backend configuration still commented out. Read steo 6 for more information.
* 
* 4. **Populate `terraform.tfvars`**
* 
* Create and populate the `terraform.tfvars` file with the obtained values:
* 
* ```terraform
* bitwarden_email                     = "your-email@example.com"
* bitwarden_master_password           = "your-master-password"
* bitwarden_client_id                 = "your-client-id"
* bitwarden_client_secret             = "your-client-secret"
* azure_state_storage_account_name    = "your-storage-account-name"
* azure_state_storage_container_name  = "your-container-name"
* azure_state_storage_key             = "your-state-key"
* azure_state_storage_subscription_id = "your-subscription-id"
* azure_state_storage_tenant_id       = "your-tenant-id"
* azure_state_storage_client_id       = "your-client-id"
* azure_state_storage_client_secret   = "your-client-secret"
* ```
* 
* 5. **Initialize and Apply Terraform Configuration**
* 
* Initialize and apply the Terraform configuration:
* 
* ```sh
* tofu init
* tofu apply
* ```
* 
* Follow the prompts to confirm the creation of resources.
* 
* 6. **Retrieve Client ID and Secret from BitWarden**
* 
* After the initial Terraform run, retrieve the client ID and client secret from BitWarden:
* 
*   1. Log in to your BitWarden account.
*   2. Navigate to the "Organization" and find the collection named "AzureSecrets".
*   3. Locate the item with the name corresponding to the Azure service principal.
*   4. Copy the `client_id` and `client_secret` values.
* 
* Update the `terraform.tfvars` file with these values:
* 
* ```terraform
* azure_state_storage_client_id     = "retrieved-client-id"
* azure_state_storage_client_secret = "retrieved-client-secret"
* ```
* 
* 7. **Update Backend Configuration**
* 
* After the resources are created, update the backend configuration in `providers.tf` to use the newly created Azure Storage Account and Container.
* 
* 8. **Migrate State**
* 
* Migrate the Terraform state to the new backend:
* 
* ```sh
* terraform init -migrate-state
* ```
* 
* This will move the state files to the Azure Storage Account and Container.
*/

data "bitwarden_organization" "starfleet_organization" {
  search = var.bitwarden_organization
}

data "bitwarden_org_collection" "azuresecrets" {
  search          = var.bitwarden_org_collection
  organization_id = data.bitwarden_organization.starfleet_organization.id
}

data "azuread_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "starfleet_home_automation_rg" {
  name     = var.azure_resource_group_name
  location = var.azure_resource_group_location
}

resource "azurerm_storage_account" "starfleet_general_storage" {
  name                            = var.azure_general_storage_account_name
  resource_group_name             = azurerm_resource_group.starfleet_home_automation_rg.name
  location                        = azurerm_resource_group.starfleet_home_automation_rg.location
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

resource "azurerm_storage_container" "starfleet_home_automation_state_storage_container" {
  name                  = var.azure_state_storage_container_name
  storage_account_name  = azurerm_storage_account.starfleet_general_storage.name
  container_access_type = "private"
}

resource "bitwarden_item_login" "azure_state_storage_container_details" {
  name     = "${azurerm_storage_container.starfleet_home_automation_state_storage_container.name}-connection-details"
  username = ""
  password = ""

  organization_id = data.bitwarden_organization.starfleet_organization.id
  collection_ids  = [data.bitwarden_org_collection.azuresecrets.id]

  field {
    name = "id"
    text = azurerm_storage_container.starfleet_home_automation_state_storage_container.id
  }

  field {
    name = "resource_manager_id"
    text = azurerm_storage_container.starfleet_home_automation_state_storage_container.resource_manager_id
  }

  field {
    name = "storage_account_name"
    text = azurerm_storage_container.starfleet_home_automation_state_storage_container.storage_account_name
  }

  field {
    name = "storage_container_name"
    text = azurerm_storage_container.starfleet_home_automation_state_storage_container.name
  }

  field {
    name = "resource_group_name"
    text = azurerm_storage_account.starfleet_general_storage.resource_group_name
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

// Create groups for different access levels
resource "azuread_group" "subscription_owner_group" {
  display_name = var.azure_subscription_owner_group
  members = [
    azuread_service_principal.terraform_sp.object_id,
    data.azuread_client_config.current.object_id
  ]
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}

resource "azuread_group" "storage_account_owner_group" {
  display_name = var.azure_storage_account_owner_group
  members = [
    azuread_service_principal.terraform_sp.object_id,
    data.azuread_client_config.current.object_id
  ]
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}

resource "azuread_group" "state_container_data_owner_group" {
  display_name = var.state_container_data_owner_group
  members = [
    azuread_service_principal.state_storage_sp.object_id,
    data.azuread_client_config.current.object_id
  ]
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}

// Create service principals
resource "azuread_application" "state_storage_sp" {
  display_name = var.state_storage_sp_display_name
  owners       = [data.azuread_client_config.current.object_id]
  web {
    homepage_url = "https://${var.state_storage_sp_display_name}-sp"
  }
}

resource "azuread_service_principal" "state_storage_sp" {
  owners    = [data.azuread_client_config.current.object_id]
  client_id = azuread_application.state_storage_sp.client_id
}

resource "azuread_service_principal_password" "state_storage_sp" {
  service_principal_id = azuread_service_principal.state_storage_sp.object_id
}

resource "azuread_application" "terraform_sp" {
  display_name = var.terraform_sp_display_name
  owners       = [data.azuread_client_config.current.object_id]
  web {
    homepage_url = "https://${var.terraform_sp_display_name}-sp"
  }
}

resource "azuread_service_principal" "terraform_sp" {
  owners    = [data.azuread_client_config.current.object_id]
  client_id = azuread_application.terraform_sp.client_id
}

resource "azuread_service_principal_password" "terraform_sp" {
  service_principal_id = azuread_service_principal.terraform_sp.object_id
}

// Assign roles to groups
resource "azurerm_role_assignment" "state_storage_access_group_blob_owner" {
  principal_id         = azuread_group.state_container_data_owner_group.object_id
  role_definition_name = "Storage Blob Data Owner"
  scope                = azurerm_storage_container.starfleet_home_automation_state_storage_container.resource_manager_id
}

resource "azurerm_role_assignment" "subscription_owner_role" {
  principal_id         = azuread_group.subscription_owner_group.object_id
  role_definition_name = "Owner"
  scope                = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "storage_account_owner_role" {
  principal_id         = azuread_group.storage_account_owner_group.object_id
  role_definition_name = "Storage Account Contributor"
  scope                = azurerm_storage_account.starfleet_general_storage.id
}

// Update BitWarden secrets
resource "bitwarden_item_login" "azure_state_storage_user" {
  name     = azuread_service_principal.state_storage_sp.display_name
  username = azuread_service_principal.state_storage_sp.client_id
  password = azuread_service_principal_password.state_storage_sp.value

  organization_id = data.bitwarden_organization.starfleet_organization.id
  collection_ids  = [data.bitwarden_org_collection.azuresecrets.id]

  field {
    name = "object_id"
    text = azuread_service_principal.state_storage_sp.object_id
  }

  field {
    name = "client_id"
    text = azuread_service_principal.state_storage_sp.client_id
  }

  field {
    name = "tenant_id"
    text = data.azuread_client_config.current.tenant_id
  }
}

resource "bitwarden_item_login" "terraform_user" {
  name     = azuread_service_principal.terraform_sp.display_name
  username = azuread_service_principal.terraform_sp.client_id
  password = azuread_service_principal_password.terraform_sp.value

  organization_id = data.bitwarden_organization.starfleet_organization.id
  collection_ids  = [data.bitwarden_org_collection.azuresecrets.id]

  field {
    name = "object_id"
    text = azuread_service_principal.terraform_sp.object_id
  }

  field {
    name = "client_id"
    text = azuread_service_principal.terraform_sp.client_id
  }

  field {
    name = "tenant_id"
    text = data.azuread_client_config.current.tenant_id
  }
}
