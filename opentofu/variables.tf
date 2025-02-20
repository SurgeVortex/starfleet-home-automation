variable "bitwarden_email" {
  description = "Email to use to log into BitWarden."
  type        = string
}

variable "bitwarden_master_password" {
  description = "Password to log into bitwarden to."
  type        = string
}

variable "bitwarden_client_id" {
  description = "Bitwarden API Client ID"
  type        = string
}

variable "bitwarden_client_secret" {
  description = "Bitwarden API Client Secret"
  type        = string
}

variable "azure_state_storage_account_name" {
  description = "Storage Account name that contains the container to store state files in."
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
  description = "Subscription ID containig the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_state_storage_tenant_id" {
  description = "Tenant ID containig the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_state_storage_client_id" {
  description = "Client ID containig the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure_state_storage_client_secret" {
  description = "Subscription containig the Azure Storage Container to store the state files in."
  type        = string
}
