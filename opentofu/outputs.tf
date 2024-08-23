# Terraform Outputs
output "Unifi-Network-VLANs" {
  value = unifi_network.vlans
}

output "Unifi-Firewall-Groups" {
  value = unifi_firewall_group.firewall-groups
}

output "Unifi-Firewall-Rules" {
  value = unifi_firewall_rule.vlan-firewall-rules
}

output "Unifi-User-Groups" {
  value = unifi_user_group.user-groups
}

output "Unifi-Users" {
  value = unifi_user.users
}

output "Unifi-Default-AP-Group" {
  value = data.unifi_ap_group.default
}

output "Unifi-WiFi-Configs" {
  sensitive = true
  value     = unifi_wlan.wifi
}
