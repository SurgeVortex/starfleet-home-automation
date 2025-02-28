variable "bitwarden_email" {
  description = "Email to use to log into BitWarden."
  type        = string
}

variable "bitwarden_master_password" {
  description = "Password to log into BitWarden."
  type        = string
}

variable "bitwarden_client_id" {
  description = "BitWarden API Client ID."
  type        = string
}

variable "bitwarden_client_secret" {
  description = "BitWarden API Client Secret."
  type        = string
}

variable "bitwarden_organization" {
  description = "BitWarden Organization that secrets live in."
  type        = string
  default     = "starfleet-home-automation"
}

variable "bitwarden_org_collection" {
  description = "BitWarden Collection that secrets live in."
  type        = string
}

variable "azure_resource_group_name" {
  description = "Name of the resource group to create in Azure."
  type        = string
}

variable "azure_resource_group_location" {
  description = "Location of the resource group to create in Azure."
  type        = string
}

variable "azure_state_storage_container_name" {
  description = "Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_state_storage_key" {
  description = "Name of the state storage file."
  type        = string
}

variable "azure_state_storage_subscription_id" {
  description = "Subscription ID containing the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_state_storage_tenant_id" {
  description = "Tenant ID containing the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_state_storage_client_id" {
  description = "Client ID containing the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_state_storage_client_secret" {
  description = "Client Secret containing the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_general_storage_account_name" {
  description = "The name for the Azure general storage account."
  type        = string
}

variable "state_storage_sp_display_name" {
  description = "The display name for the state storage service principal."
  type        = string
}

variable "terraform_sp_display_name" {
  description = "The display name for the Terraform service principal."
  type        = string
}

variable "azure_subscription_owner_group" {
  description = "The display name for the Azure subscription owner group."
  type        = string
}

variable "azure_storage_account_owner_group" {
  description = "The display name for the Azure storage account owner group."
  type        = string
}

variable "state_container_data_owner_group" {
  description = "The display name for the Azure container owner group."
  type        = string
}

variable "terraform_sp_client_id" {
  description = "Client ID of the Terraform service principal."
  type        = string
}

variable "terraform_sp_client_secret" {
  description = "Client Secret of the Terraform service principal."
  type        = string
}
