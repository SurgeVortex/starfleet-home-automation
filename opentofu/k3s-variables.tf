variable "k3s_config_mode" {
  description = "The mode for the K3s kubeconfig"
  default     = "644"
  type        = string
}

variable "bitwarden_github_pat_credentials_name" {
  description = "Credentials for GitHub Personal Access Token."
  type        = string
  default     = "GitHub PAT"
}

variable "bitwarden_age_keys_name" {
  description = "Credentials for age keys."
  type        = string
  default     = "Age Keys"
}
