variable "bitwarden-email" {
  description = "Email to use to log into BitWarden."
  type        = string
}

variable "bitwarden-master-password" {
  description = "Password to log into bitwarden to."
  type        = string
}

variable "bitwarden-client-id" {
  description = "Bitwarden API Client ID"
  type        = string
}

variable "bitwarden-client-secret" {
  description = "Bitwarden API Client Secret"
  type        = string
}

variable "bitwarden-organization" {
  description = "BitWarden Organization that secrets live in"
  type        = string
  default     = "starfleet-home-automation"
}

variable "azure-state-storage-account-name" {
  description = "Storage Account name that contains the container to store state files in."
  type        = string
}

variable "azure-state-storage-container-name" {
  description = "Azure Storage Container to store the state files in."
  type        = string
}

variable "azure-state-storage-key" {
  description = "Name of the state storage file."
  type        = string
}

variable "azure-state-storage-subscription-id" {
  description = "Subscription ID containig the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure-state-storage-tenant-id" {
  description = "Tenant ID containig the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure-state-storage-client-id" {
  description = "Client ID containig the Azure Storage Container to store the state files in."
  type        = string
}

variable "azure-state-storage-client-secret" {
  description = "Subscription containig the Azure Storage Container to store the state files in."
  type        = string
}
