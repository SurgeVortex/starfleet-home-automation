variable "k3s-controlplane-ip" {
  description = "The IP address of the K3s control plane"
  default     = "192.168.40.10"
  type        = string
}

variable "k3s-loadbalancer-ip-range" {
  description = "The IP range for the K3s load balancer"
  default     = ""
  type        = string
}

variable "k3s-config-mode" {
  description = "The mode for the K3s kubeconfig"
    default     = "644"
    type        = string
}

variable "trigger-k3s-install" {
  description = "Trigger the installation of K3s"
  default     = true
  type        = bool
}
