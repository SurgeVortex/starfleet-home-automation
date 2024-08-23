# Terraform Variables
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

# variable "bitwarden-organization" {
#   description = "BitWarden Organization that secrets live in"
#   type        = string
#   default     = "starfleet-home-automation"
# }


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

variable "unifi-credentials-name" {
  description = ""
  type        = string
  default     = "Unifi Local Admin"
}

variable "unifi-api-url" {
  description = ""
  type        = string
  default     = "https://unifi/"
}

variable "unifi-insecure" {
  description = ""
  type        = bool
  default     = true
}

variable "unifi-vlans" {
  description = "Map of VLANs"
  type = map(object({
    id                  = number
    name                = string
    purpose             = string
    cidr                = string
    gateway             = string
    dhcp-start          = string
    dhcp-end            = string
    dns-servers         = list(string)
    pxe-server          = string
    ports               = list(number)
    rate-limit          = bool
    internet            = bool
    networks-allow-to   = list(string)
    networks-allow-from = list(string)
    networks-deny-to    = list(string)
    networks-deny-from  = list(string)
  }))

  default = {
    management = {
      id                  = 10
      name                = "Management VLAN"
      purpose             = "corporate"
      cidr                = "192.168.10.0/24"
      gateway             = "192.168.10.1"
      dhcp-start          = "192.168.10.100"
      dhcp-end            = "192.168.10.200"
      dns-servers         = ["1.1.1.1"]
      pxe-server          = "192.168.10.2"
      ports               = [1]
      rate-limit          = false
      internet            = true
      networks-allow-to   = []
      networks-allow-from = []
      networks-deny-to    = []
      networks-deny-from  = []
    }
  }
}

variable "unifi-user-groups" {
  description = "list of unifi user groups"
  type = map(object({
    qos_rate_max_down = number
    qos_rate_max_up   = number
  }))
  default = {
    "trusted" = {
      qos_rate_max_down = -1
      qos_rate_max_up   = -1
    }
  }
}

variable "unifi-trusted-clients" {
  description = "Map of trusted clients"
  type = map(object({
    mac          = string
    name         = string
    note         = optional(string)
    fixed_ip     = optional(string)
    device_id    = optional(number)
    network_name = string
  }))
  default = {
    "Chris-Mac-Book-Pro-LAN" = {
      mac          = "00:11:22:33:44:55"
      name         = "Chris-Mac-Book-Pro-LAN"
      network_name = "trusted"
    }
  }
}

variable "unifi-wlans" {
  description = "Map of WiFi Configs"
  type = map(object({
    ssid               = string
    security           = string
    passphrase         = string
    network_name       = string
    is_guest           = bool
    mac_filter_enabled = bool
    mac_filter_policy  = string
    l2_isolation       = bool
  }))
  default = {
    "SurgeWiFiAP" = {
      ssid               = "SurgeWiFiAP"
      security           = "wpapsk"
      passphrase         = "12345678"
      network_name       = "trusted"
      is_guest           = false
      mac_filter_enabled = true
      mac_filter_policy  = "allow"
      l2_isolation       = false
    }
  }
}
