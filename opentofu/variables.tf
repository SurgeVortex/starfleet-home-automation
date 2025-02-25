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

variable "bitwarden_org_collection" {
  description = "BitWarden Collection that secrets live in"
  type        = string
  default     = "AzureSecrets"
}

variable "bitwarden_organization" {
  description = "BitWarden Organization that secrets live in"
  type        = string
  default     = "starfleet-home-automation"
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

variable "azure_application_longhorn_backup_display_name" {
  description = "Display name for the Azure Application used for Longhorn backup."
  type        = string
  default     = "lognhorn-backup-sp"
}

variable "azure_longhorn_backup_container_name" {
  description = "Name of the Azure Storage Container to store Longhorn backups in."
  type        = string
  default     = "longhorn-backups"
}
