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

variable "trigger_k3s_install" {
  description = "Trigger the installation of K3s"
  default     = true
  type        = bool
}
