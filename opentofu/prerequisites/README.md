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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.8.1 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.53.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.116.0 |
| <a name="requirement_bitwarden"></a> [bitwarden](#requirement\_bitwarden) | ~> 0.8.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.53.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.116.0 |
| <a name="provider_bitwarden"></a> [bitwarden](#provider\_bitwarden) | 0.8.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.state-storage-service-principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_service_principal.state-storage-service-principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_password.state-storage-service-principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_password) | resource |
| [azurerm_resource_group.starfleet-home-automation-rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.state-storage-service-principal-blod-owner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.starfleet-home-automation-storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.starfleet-home-automation-state-storage-container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [bitwarden_item_login.azure-state-storage-container-details](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/resources/item_login) | resource |
| [bitwarden_item_login.azure-state-storage-user](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/resources/item_login) | resource |
| [bitwarden_org_collection.azuresecrets](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/resources/org_collection) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [bitwarden_organization.starfleet-organization](https://registry.terraform.io/providers/maxlaverse/bitwarden/latest/docs/data-sources/organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure-state-storage-account-name"></a> [azure-state-storage-account-name](#input\_azure-state-storage-account-name) | Storage Account name that contains the container to store state files in. | `string` | n/a | yes |
| <a name="input_azure-state-storage-client-id"></a> [azure-state-storage-client-id](#input\_azure-state-storage-client-id) | Client ID containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure-state-storage-client-secret"></a> [azure-state-storage-client-secret](#input\_azure-state-storage-client-secret) | Subscription containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure-state-storage-container-name"></a> [azure-state-storage-container-name](#input\_azure-state-storage-container-name) | Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure-state-storage-key"></a> [azure-state-storage-key](#input\_azure-state-storage-key) | Name of the state storage file. | `string` | n/a | yes |
| <a name="input_azure-state-storage-subscription-id"></a> [azure-state-storage-subscription-id](#input\_azure-state-storage-subscription-id) | Subscription ID containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_azure-state-storage-tenant-id"></a> [azure-state-storage-tenant-id](#input\_azure-state-storage-tenant-id) | Tenant ID containig the Azure Storage Container to store the state files in. | `string` | n/a | yes |
| <a name="input_bitwarden-client-id"></a> [bitwarden-client-id](#input\_bitwarden-client-id) | Bitwarden API Client ID | `string` | n/a | yes |
| <a name="input_bitwarden-client-secret"></a> [bitwarden-client-secret](#input\_bitwarden-client-secret) | Bitwarden API Client Secret | `string` | n/a | yes |
| <a name="input_bitwarden-email"></a> [bitwarden-email](#input\_bitwarden-email) | Email to use to log into BitWarden. | `string` | n/a | yes |
| <a name="input_bitwarden-master-password"></a> [bitwarden-master-password](#input\_bitwarden-master-password) | Password to log into bitwarden to. | `string` | n/a | yes |
| <a name="input_bitwarden-organization"></a> [bitwarden-organization](#input\_bitwarden-organization) | BitWarden Organization that secrets live in | `string` | `"starfleet-home-automation"` | no |

## Outputs

No outputs.
