# Terraform Outputs
output "Unifi_Network_VLANs" {
  value     = unifi_network.vlans
  sensitive = true
}

output "Unifi_Firewall_Groups" {
  value     = unifi_firewall_group.firewall_groups
  sensitive = true
}

output "Unifi_Firewall_Rules" {
  value     = unifi_firewall_rule.vlan_firewall_rules
  sensitive = true
}

output "Unifi_User_Groups" {
  value     = unifi_user_group.user_groups
  sensitive = true
}

output "Unifi_Users" {
  value     = unifi_user.users
  sensitive = true
}

output "Unifi_Default_AP_Group" {
  value     = data.unifi_ap_group.default
  sensitive = true
}

output "Unifi_WiFi_Configs" {
  sensitive = true
  value     = unifi_wlan.wifi
}

output "Proxmox_VMs" {
  value     = proxmox_virtual_environment_vm.virtual_machines
  sensitive = true
}

output "Proxmox_Contaienrss" {
  value     = proxmox_virtual_environment_container.containers
  sensitive = true
}
