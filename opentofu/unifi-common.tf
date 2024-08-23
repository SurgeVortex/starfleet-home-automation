locals {
  firewall-rules-allow-to = flatten([
    for key, value in var.unifi-vlans : [
      for group in value.networks-allow-to : {
        key                    = "lan-out-allow-${key}-to-${group}"
        name                   = "Allow from ${value.name} to ${var.unifi-vlans[group].name}"
        action                 = "accept"
        ruleset                = "LAN_OUT"
        rule_index             = "40${value.id + 3}${index(var.unifi-vlans[key].networks-allow-to, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall-groups[key].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall-groups[group].id]
      }
    ]
  ])
  firewall-rules-allow-from = flatten([
    for key, value in var.unifi-vlans : [
      for group in value.networks-allow-from : {
        key                    = "lan-in-allow-${group}-to-${key}"
        name                   = "Allow from ${var.unifi-vlans[group].name} to ${value.name}"
        action                 = "accept"
        ruleset                = "LAN_IN"
        rule_index             = "40${value.id + 4}${index(var.unifi-vlans[key].networks-allow-from, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall-groups[group].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall-groups[key].id]
      }
    ]
  ])
  firewall-rules-deny-to = flatten([
    for key, value in var.unifi-vlans : [
      for group in value.networks-deny-to : {
        key                    = "lan-out-deny-${key}-to-${group}"
        name                   = "Deny from ${value.name} to ${var.unifi-vlans[group].name}"
        action                 = "drop"
        ruleset                = "LAN_OUT"
        rule_index             = "40${value.id + 2}${index(var.unifi-vlans[key].networks-deny-to, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall-groups[key].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall-groups[group].id]
      }
    ]
  ])
  firewall-rules-deny-from = flatten([
    for key, value in var.unifi-vlans : [
      for group in value.networks-deny-from : {
        key                    = "lan-in-deny-${group}-to-${key}"
        name                   = "Deny from ${var.unifi-vlans[group].name} to ${value.name}"
        action                 = "drop"
        ruleset                = "LAN_IN"
        rule_index             = "40${value.id + 1}${index(var.unifi-vlans[key].networks-deny-from, group)}"
        protocol               = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall-groups[group].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall-groups[key].id]
      }
    ]
  ])
  firewall-rules = merge(
    { for rule in local.firewall-rules-deny-from : rule.key => rule },
    merge(
      { for rule in local.firewall-rules-deny-to : rule.key => rule },
      merge(
        { for rule in local.firewall-rules-allow-to : rule.key => rule },
        { for rule in local.firewall-rules-allow-from : rule.key => rule }
      )
    )
  )
}

data "bitwarden_item_login" "unifi-credentials" {
  search = var.unifi-credentials-name
}

resource "unifi_network" "vlans" {
  for_each = var.unifi-vlans
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

resource "unifi_firewall_group" "firewall-groups" {
  for_each   = var.unifi-vlans
  name       = each.key
  type       = "address-group"
  members    = [each.value.cidr]
  depends_on = [unifi_network.vlans]
}

resource "unifi_firewall_rule" "vlan-firewall-rules" {
  for_each               = local.firewall-rules
  name                   = each.value.name
  action                 = each.value.action
  ruleset                = each.value.ruleset
  rule_index             = each.value.rule_index
  protocol               = each.value.protocol
  src_firewall_group_ids = each.value.src_firewall_group_ids
  dst_firewall_group_ids = each.value.dst_firewall_group_ids
}

resource "unifi_user_group" "user-groups" {
  for_each          = var.unifi-user-groups
  name              = each.key
  qos_rate_max_down = each.value.qos_rate_max_down
  qos_rate_max_up   = each.value.qos_rate_max_up
}

resource "unifi_user" "users" {
  for_each        = var.unifi-trusted-clients
  mac             = each.value.mac
  name            = each.value.name
  note            = try(each.value.note, null)
  fixed_ip        = try(each.value.fixed_ip, null)
  dev_id_override = try(each.value.device_id, 0)
  network_id      = unifi_network.vlans[each.value.network_name].id
  user_group_id   = unifi_user_group.user-groups[each.value.network_name].id
}

data "unifi_ap_group" "default" {
}

resource "unifi_wlan" "wifi" {
  for_each           = var.unifi-wlans
  name               = each.value.ssid
  security           = each.value.security
  passphrase         = each.value.passphrase
  network_id         = unifi_network.vlans[each.value.network_name].id
  is_guest           = each.value.is_guest
  mac_filter_enabled = each.value.mac_filter_enabled
  mac_filter_list    = [for mac in var.unifi-trusted-clients : mac.mac if mac.network_name == each.value.network_name]
  mac_filter_policy  = each.value.mac_filter_policy
  ap_group_ids       = [data.unifi_ap_group.default.id]
  user_group_id      = unifi_user_group.user-groups[each.value.network_name].id
}
