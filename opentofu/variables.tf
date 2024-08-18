# Terraform Variables
variable "vlans" {
  description = "Map of VLANs"
  type = map(object({
    id          = number
    name        = string
    cidr        = string
    gateway     = string
    dhcp_start  = string
    dhcp_end    = string
    dns_servers = list(string)
    ports       = list(number)
    rate_limit  = bool
    access = object({
      internet       = bool
      networks_allow = list(string)
      networks_deny  = list(string)
    })
  }))

  default = {
    management = {
      id          = 10
      name        = "Management VLAN"
      cidr        = "192.168.10.0/24"
      gateway     = "192.168.10.1"
      dhcp_start  = "192.168.10.100"
      dhcp_end    = "192.168.10.200"
      dns_servers = ["1.1.1.1"]
      ports       = [1]
      rate_limit  = false
      access = {
        internet       = true
        networks_allow = []
        networks_deny  = []
      }
    }
  }
}
