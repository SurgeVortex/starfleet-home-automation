# Terraform Outputs
output "Unifi-Network-VLANs" {
  value = unifi_network.vlans
  sensitive = true
}

output "Unifi-Firewall-Groups" {
  value = unifi_firewall_group.firewall-groups
  sensitive = true
}

output "Unifi-Firewall-Rules" {
  value = unifi_firewall_rule.vlan-firewall-rules
  sensitive = true
}

output "Unifi-User-Groups" {
  value = unifi_user_group.user-groups
  sensitive = true
}

output "Unifi-Users" {
  value = unifi_user.users
  sensitive = true
}

output "Unifi-Default-AP-Group" {
  value     = data.unifi_ap_group.default
  sensitive = true
}

output "Unifi-WiFi-Configs" {
  sensitive = true
  value     = unifi_wlan.wifi
}

output "Proxmox-VMs" {
  value     = proxmox_virtual_environment_vm.virtual-machines
  sensitive = true
}
