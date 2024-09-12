variable "proxmox-credentials-name" {
  description = "Credentials to log into Proxmox server."
  type        = string
  default     = "Proxmox Local Admin"
}

variable "ssh-credentials-name" {
  description = "Credentials for Proxmox Instances."
  type        = string
  default     = "SSH Credentials"
}

variable "bitwarden-api-credentials-name" {
  description = "Credentials for BitWarden API access."
  type        = string
  default     = "Bitwarden API Credentials"
}

variable "proxmox-cloud-images" {
  description = "Cloud images to download."
  type = map(object({
    content_type = string
    datastore_id = string
    node_name    = string
    url          = string
  }))
  default = {
    "ubuntu_cloud_image" = {
      content_type = "iso"
      datastore_id = "local"
      node_name    = "pve-1"
      url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    }
  }
}

variable "proxmox-vms" {
  description = "Map of VMs"
  default     = {}
  type = map(object({
    bios = optional(string)
    cpu = object({
      architecture = optional(string)
      cores        = number
      sockets      = number
    })
    description = optional(string)
    device_id   = optional(number)
    disk = map(object({
      backup       = optional(bool)
      datastore_id = string
      file_id      = optional(string)
      interface    = string
      size         = number
    }))
    efi_disk = optional(object({
      datastore_id      = optional(string)
      file_format       = optional(string)
      type              = optional(string)
      pre_enrolled_keys = optional(bool)
    }))
    tpm_state = optional(object({
      datastore_id = optional(string)
      version      = optional(string)
    }))
    initialization = optional(object({
      datastore_id = optional(string)
      interface    = optional(string)
      dns = optional(object({
        servers = optional(list(string))
      }))
      ip_config = optional(object({
        ipv4 = optional(object({
          address = optional(string)
          gateway = optional(string)
        }))
      }))
      user_account = optional(object({
        keys     = optional(list(string))
        username = optional(string)
        password = optional(string)
      }))
    }))
    is_cloud_init   = optional(bool, false)
    keyboard_layout = optional(string)
    memory = object({
      dedicated = number
      floating  = optional(number, 0)
      shared    = optional(number, 0)
    })
    name = string
    network_device = map(object({
      bridge  = optional(string, "vmbr0")
      model   = optional(string, "virtio")
      vlan_id = optional(number, "40")
    }))
    node_name = string
    on_boot   = optional(bool, true)
    operating_system = optional(object({
      type = optional(string)
    }))
    pool_id = optional(string)
    started = optional(bool, true)
    startup = optional(object({
      order = number
    }))
    vm_id = number
  }))
}
