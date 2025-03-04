variable "proxmox_credentials_name" {
  description = "Credentials to log into Proxmox server."
  type        = string
  default     = "Proxmox Local Admin"
}

variable "ssh_credentials_name" {
  description = "Credentials for Proxmox Instances."
  type        = string
  default     = "SSH Credentials"
}

variable "bitwarden_api_credentials_name" {
  description = "Credentials for BitWarden API access."
  type        = string
  default     = "Bitwarden API Credentials"
}

variable "proxmox_cloud_images" {
  description = "Cloud images to download."
  type = map(object({
    content_type = string
    datastore_id = string
    node_name    = string
    url          = string
    file_name    = string
  }))
  default = {
    "ubuntu_cloud_image" = {
      content_type = "iso"
      datastore_id = "local"
      node_name    = "pve-1"
      file_name    = "jammy-server-cloudimg-amd64.img"
      url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    }
  }
}

variable "proxmox_vms" {
  description = "Map of Proxmox VMs"
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

variable "proxmox_containers" {
  description = "Map of Proxmox containers"
  default     = {}
  type = map(object({
    node_name = string
    vm_id     = number
    cpu = optional(object({
      architecture = optional(string, "amd64")
      cores        = optional(number, 1)
    }))
    description = optional(string)
    disk = optional(object({
      datastore_id = optional(string, "local")
      size         = optional(number, 4)
    }))
    initialization = optional(object({
      dns = optional(object({
        domain  = optional(string)
        servers = optional(list(string))
      }))
      hostname = optional(string)
      ip_config = optional(object({
        ipv4 = optional(object({
          address = optional(string)
          gateway = optional(string)
        }))
      }))
      user_account = optional(object({
        keys     = optional(list(string))
        password = optional(string)
      }))
    }))
    is_cloud_init = optional(bool, false)
    memory = optional(object({
      dedicated = optional(number, 512)
      swap      = optional(number, 0)
    }))
    network_interface = optional(map(object({
      bridge  = optional(string, "vmbr0")
      name    = optional(string, "eth0")
      vlan_id = optional(number, "40")
    })))
    operating_system = object({
      template_file_id = string
    })
    pool_id = optional(string)
    started = optional(bool, true)
    startup = optional(object({
      order = number
    }))
    start_on_boot = optional(bool, true)
    unprivileged  = optional(bool, false)
  }))
}
