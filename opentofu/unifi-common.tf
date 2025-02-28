locals {
  firewall_rules_allow_to = flatten([
    for key, value in var.unifi_vlans : [
      for group in value.networks-allow-to : {
        key                    = "lan-out-allow-${key}-to-${group}"
        name                   = "Allow from ${value.name} to ${var.unifi_vlans[group].name}"
        action                 = "accept"
        ruleset                = "LAN_OUT"
        rule_index             = "40${value.id + 3}${index(var.unifi_vlans[key].networks-allow-to, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall_groups[key].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall_groups[group].id]
      }
    ]
  ])
  firewall_rules_allow_from = flatten([
    for key, value in var.unifi_vlans : [
      for group in value.networks-allow-from : {
        key                    = "lan-in-allow-${group}-to-${key}"
        name                   = "Allow from ${var.unifi_vlans[group].name} to ${value.name}"
        action                 = "accept"
        ruleset                = "LAN_IN"
        rule_index             = "40${value.id + 4}${index(var.unifi_vlans[key].networks-allow-from, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall_groups[group].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall_groups[key].id]
      }
    ]
  ])
  firewall_rules_deny_to = flatten([
    for key, value in var.unifi_vlans : [
      for group in value.networks-deny-to : {
        key                    = "lan-out-deny-${key}-to-${group}"
        name                   = "Deny from ${value.name} to ${var.unifi_vlans[group].name}"
        action                 = "drop"
        ruleset                = "LAN_OUT"
        rule_index             = "40${value.id + 2}${index(var.unifi_vlans[key].networks-deny-to, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall_groups[key].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall_groups[group].id]
      }
    ]
  ])
  firewall_rules_deny_from = flatten([
    for key, value in var.unifi_vlans : [
      for group in value.networks-deny-from : {
        key                    = "lan-in-deny-${group}-to-${key}"
        name                   = "Deny from ${var.unifi_vlans[group].name} to ${value.name}"
        action                 = "drop"
        ruleset                = "LAN_IN"
        rule_index             = "40${value.id + 1}${index(var.unifi_vlans[key].networks-deny-from, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall_groups[group].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall_groups[key].id]
      }
    ]
  ])
  firewall_rules = merge(
    { for rule in local.firewall_rules_deny_from : rule.key => rule },
    merge(
      { for rule in local.firewall_rules_deny_to : rule.key => rule },
      merge(
        { for rule in local.firewall_rules_allow_to : rule.key => rule },
        { for rule in local.firewall_rules_allow_from : rule.key => rule }
      )
    )
  )
}

data "bitwarden_item_login" "unifi_credentials" {
  search = var.unifi_credentials_name
}

resource "unifi_network" "vlans" {
  for_each = var.unifi_vlans
  name     = each.value.name
  purpose  = each.value.purpose

  subnet                  = each.value.cidr
  vlan_id                 = each.value.id
  dhcp_start              = each.value.dhcp-start
  dhcp_stop               = each.value.dhcp-end
  dhcp_enabled            = true
  dhcp_dns                = each.value.dns-servers
  dhcpd_boot_server       = each.value.pxe-server
  internet_access_enabled = each.value.internet
}

resource "unifi_firewall_group" "firewall_groups" {
  for_each   = var.unifi_vlans
  name       = each.key
  type       = "address-group"
  members    = [each.value.cidr]
  depends_on = [unifi_network.vlans]
}

resource "unifi_firewall_rule" "vlan_firewall_rules" {
  for_each               = local.firewall_rules
  name                   = each.value.name
  action                 = each.value.action
  ruleset                = each.value.ruleset
  rule_index             = each.value.rule_index
  protocol               = each.value.protocol
  src_firewall_group_ids = each.value.src_firewall_group_ids
  dst_firewall_group_ids = each.value.dst_firewall_group_ids
}

resource "unifi_user_group" "user_groups" {
  for_each          = var.unifi_user_groups
  name              = each.key
  qos_rate_max_down = each.value.qos_rate_max_down
  qos_rate_max_up   = each.value.qos_rate_max_up
}

resource "unifi_user" "users" {
  for_each        = var.unifi_trusted_clients
  mac             = each.value.mac
  name            = each.value.name
  note            = try(each.value.note, null)
  fixed_ip        = try(each.value.fixed_ip, null)
  dev_id_override = try(each.value.device_id, 0)
  network_id      = unifi_network.vlans[each.value.network_name].id
  user_group_id   = unifi_user_group.user_groups[each.value.network_name].id
}

resource "unifi_user" "servers" {
  for_each        = var.proxmox_vms
  mac             = lower(proxmox_virtual_environment_vm.virtual_machines[each.key].network_device[0].mac_address)
  name            = each.value.name
  note            = each.value.description != null ? each.value.description : "Server Hosted on Proxmox"
  fixed_ip        = try(split("/", proxmox_virtual_environment_vm.virtual_machines[each.key].ip_config[0].ipv4[0].address)[0], null)
  dev_id_override = try(each.value.device_id, 0)
  network_id      = unifi_network.vlans["servers"].id
  user_group_id   = unifi_user_group.user_groups["servers"].id
}

data "unifi_ap_group" "default" {
  name = "default"
}

resource "unifi_wlan" "wifi" {
  for_each           = var.unifi_wlans
  name               = each.value.ssid
  security           = each.value.security
  passphrase         = each.value.passphrase
  network_id         = unifi_network.vlans[each.value.network_name].id
  is_guest           = each.value.is_guest
  mac_filter_enabled = each.value.mac_filter_enabled
  mac_filter_list    = [for mac in var.unifi_trusted_clients : mac.mac if mac.network_name == each.value.network_name]
  mac_filter_policy  = each.value.mac_filter_policy
  ap_group_ids       = [data.unifi_ap_group.default.id]
  user_group_id      = unifi_user_group.user_groups[each.value.network_name].id
}
