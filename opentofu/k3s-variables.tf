variable "k3s_controlplane_ip" {
  description = "The IP address of the K3s control plane"
  default     = "192.168.40.10"
  type        = string
}

variable "k3s_loadbalancer_ip_range" {
  description = "The IP range for the K3s load balancer"
  default     = "192.168.40.20-192.168.40.30"
  type        = string
}

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
