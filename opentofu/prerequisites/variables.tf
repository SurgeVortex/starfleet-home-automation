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

variable "bitwarden-folder" {
  description = "Name of the folder all automation secrets are kept in."
  type = string
  default = "starfleet-home-automation"
}
