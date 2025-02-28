# Azure Storage Account and Container for Terraform State

This Terraform configuration creates an Azure Storage Account and Container to store Terraform state files. Additionally, it securely stores the secrets of the created resources in BitWarden.

## Overview

* This module creates the following resources:
  * Azure Storage Account
  * Azure Storage Container
  * BitWarden Organization Collection for storing Azure secrets

## Requirements
* Azure subscription with sufficient permissions to create Storage Accounts and Containers
* BitWarden account with Organization setup

## Important Notes

* After running this configuration, you should modify the backend configuration in [opentofu/prerequisites/providers.tf] to store the state in the newly created Azure Storage Account and Container.
* To destroy the resources and keep the state files sane, you need to first set the state back to local by uncommenting the backend configuration in [opentofu/prerequisites/providers.tf] and initiating the migration by running `terraform init -migrate-state`.

## Initial Setup Instructions

### Prerequisites

* An Azure account with sufficient permissions to create resources.
* A BitWarden account with an Organization setup.

### Steps

1. **Clone the Repository**

   ```sh
   git clone https://github.com/your-repo/starfleet-home-automation.git
   cd starfleet-home-automation/opentofu/prerequisites
   ```

2. **Configure Azure CLI**

   Ensure you are logged into your Azure account:

   ```sh
   az login
   ```

3. **Obtain Required Variables**

You will need the following information to populate the `terraform.tfvars` file:

* `bitwarden_email`: Your BitWarden account email.
* `bitwarden_master_password`: Your BitWarden master password.
* `bitwarden_client_id`: Your BitWarden client ID.
* `bitwarden_client_secret`: Your BitWarden client secret.
* `azure_state_storage_account_name`: The name for the Azure Storage Account.
* `azure_state_storage_container_name`: The name for the Azure Storage Container.
* `azure_state_storage_key`: The key for the state storage.
* `azure_state_storage_subscription_id`: Your Azure subscription ID.
* `azure_state_storage_tenant_id`: Your Azure tenant ID.
* `azure_state_storage_client_id`: Your Azure client ID.
* `azure_state_storage_client_secret`: Your Azure client secret.

These values can be obtained from your Azure and BitWarden accounts.

#### How to Obtain These Values:

- **BitWarden Client ID and Secret:**
  1. Log in to your BitWarden account.
  2. Navigate to the "Settings" page.
  3. Under "API Key", generate a new client ID and secret.

- **Azure Subscription ID and Tenant ID:**
  1. Log in to the Azure portal.
  2. Navigate to "Subscriptions".
  3. Select the subscription you want to use.
  4. The subscription ID and tenant ID will be displayed on the overview page.
  5.  Alternatively, you can use the Azure CLI:

```sh
az account show --query "{subscriptionId:id, tenantId:tenantId}"
```

- **Azure Client ID and Secret:**
This will be gotten after the initial run with the backend configuration still commented out. Read step 6 for more information.

4. **Populate `terraform.tfvars`**

Create and populate the `terraform.tfvars` file with the obtained values:

```terraform
bitwarden_email                     = "your-email@example.com"
bitwarden_master_password           = "your-master-password"
bitwarden_client_id                 = "your-client-id"
bitwarden_client_secret             = "your-client-secret"
azure_state_storage_account_name    = "your-storage-account-name"
azure_state_storage_container_name  = "your-container-name"
azure_state_storage_key             = "your-state-key"
azure_state_storage_subscription_id = "your-subscription-id"
azure_state_storage_tenant_id       = "your-tenant-id"
azure_state_storage_client_id       = "your-client-id"
azure_state_storage_client_secret   = "your-client-secret"
```

5. **Initialize and Apply Terraform Configuration**

Initialize and apply the Terraform configuration:

```sh
tofu init
tofu apply
```

Follow the prompts to confirm the creation of resources.

6. **Retrieve Client ID and Secret from BitWarden**

After the initial Terraform run, retrieve the client ID and client secret from BitWarden:

  1. Log in to your BitWarden account.
  2. Navigate to the "Organization" and find the collection named "AzureSecrets".
  3. Locate the item with the name corresponding to the Azure service principal.
  4. Copy the `client_id` and `client_secret` values.

Update the `terraform.tfvars` file with these values:

```terraform
azure_state_storage_client_id     = "retrieved-client-id"
azure_state_storage_client_secret = "retrieved-client-secret"
```

7. **Update Backend Configuration**

After the resources are created, update the backend configuration in `providers.tf` to use the newly created Azure Storage Account and Container.

8. **Migrate State**

Migrate the Terraform state to the new backend:

```sh
terraform init -migrate-state
```

This will move the state files to the Azure Storage Account and Container.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.8.6 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.53.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0.0 |
| <a name="requirement_bitwarden"></a> [bitwarden](#requirement\_bitwarden) | ~> 0.8.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.53.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.0.1 |
| <a name="provider_bitwarden"></a> [bitwarden](#provider\_bitwarden) | 0.8.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.state_storage_service_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_group.state_storage_data_owner_group](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |
| [azuread_service_principal.state_storage_service_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_password.state_storage_service_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_password) | resource |
| [azurerm_resource_group.starfleet_home_automation_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.state_storage_access_group_blob_owner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.starfleet_home_automation_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.starfleet_home_automation_state_storage_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [bitwarden_item_login.azure_state_storage_container_details](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/resources/item_login) | resource |
| [bitwarden_item_login.azure_state_storage_user](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/resources/item_login) | resource |
| [bitwarden_org_collection.azuresecrets](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/resources/org_collection) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [bitwarden_organization.starfleet_organization](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/data-sources/organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_application_display_name"></a> [azure\_application\_display\_name](#input\_azure\_application\_display\_name) | Name of the application to create in Azure AD. | `string` | `"value"` | no |
| <a name="input_azure_resource_group_location"></a> [azure\_resource\_group\_location](#input\_azure\_resource\_group\_location) | Location of the resource group to create in Azure. | `string` | n/a | yes |
| <a name="input_azure_resource_group_name"></a> [azure\_resource\_group\_name](#input\_azure\_resource\_group\_name) | Name of the resource group to create in Azure. | `string` | n/a | yes |
| <a name="input_azure_state_data_owner_group"></a> [azure\_state\_data\_owner\_group](#input\_azure\_state\_data\_owner\_group) | Name of the Azure AD group to assign to the blob owner access group. | `string` | n/a | yes |
| <a name="input_azure_state_storage_account_name"></a> [azure\_state\_storage\_account\_name](#input\_azure\_state\_storage\_account\_name) | Storage Account name that contains the container to store state files in. | `string` | n/a | yes |
| <a name="input_azure_state_storage_client_id"></a> [azure\_state\_storage\_client\_id](#input\_azure\_state\_storage\_client\_id) | Client ID containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure_state_storage_client_secret"></a> [azure\_state\_storage\_client\_secret](#input\_azure\_state\_storage\_client\_secret) | Subscription containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure_state_storage_container_name"></a> [azure\_state\_storage\_container\_name](#input\_azure\_state\_storage\_container\_name) | Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure_state_storage_key"></a> [azure\_state\_storage\_key](#input\_azure\_state\_storage\_key) | Name of the state storage file. | `string` | n/a | yes |
| <a name="input_azure_state_storage_subscription_id"></a> [azure\_state\_storage\_subscription\_id](#input\_azure\_state\_storage\_subscription\_id) | Subscription ID containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure_state_storage_tenant_id"></a> [azure\_state\_storage\_tenant\_id](#input\_azure\_state\_storage\_tenant\_id) | Tenant ID containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_bitwarden_client_id"></a> [bitwarden\_client\_id](#input\_bitwarden\_client\_id) | Bitwarden API Client ID | `string` | n/a | yes |
| <a name="input_bitwarden_client_secret"></a> [bitwarden\_client\_secret](#input\_bitwarden\_client\_secret) | Bitwarden API Client Secret | `string` | n/a | yes |
| <a name="input_bitwarden_email"></a> [bitwarden\_email](#input\_bitwarden\_email) | Email to use to log into BitWarden. | `string` | n/a | yes |
| <a name="input_bitwarden_master_password"></a> [bitwarden\_master\_password](#input\_bitwarden\_master\_password) | Password to log into bitwarden to. | `string` | n/a | yes |
| <a name="input_bitwarden_org_collection"></a> [bitwarden\_org\_collection](#input\_bitwarden\_org\_collection) | BitWarden Collection that secrets live in | `string` | n/a | yes |
| <a name="input_bitwarden_organization"></a> [bitwarden\_organization](#input\_bitwarden\_organization) | BitWarden Organization that secrets live in | `string` | `"starfleet-home-automation"` | no |

## Outputs

No outputs.
