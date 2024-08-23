# # Main Terraform Configuration
# locals {
#   storage-container-secrets = { for field in data.bitwarden_item_login.storage-container-connection-details.field : field.name => field.text }
#   state-storage-user-secrets = { for field in data.bitwarden_item_login.azure-state-storage-user.field : field.name => field.text }
# }

# data "bitwarden_item_login" "storage-container-connection-details" {
#   search     = "${var.}-connection-details"
#   depends_on = [bitwarden_item_login.azure-state-storage-container-details]
# }

# data "bitwarden_item_login" "azure-state-storage-user" {
#   search     = azuread_service_principal.state-storage-service-principal.display_name
#   depends_on = [bitwarden_item_login.azure-state-storage-user]
# }

locals {
  firewall-rules-allow-to = flatten([
    for key, value in var.vlans : [
      for group in value.networks-allow-to : {
        key            = "lan-out-allow-${key}-to-${group}"
        name           = "Allow from ${value.name} to ${var.vlans[group].name}"
        action         = "accept"
        ruleset        = "LAN_OUT"
        rule_index     = "40${value.id + 3}${index(var.vlans[key].networks-allow-to, group)}"
        protocol       = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall-groups[key].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall-groups[group].id]
      }
    ]
  ])
  firewall-rules-allow-from = flatten([
    for key, value in var.vlans : [
      for group in value.networks-allow-from : {
        key            = "lan-in-allow-${group}-to-${key}"
        name           = "Allow from ${var.vlans[group].name} to ${value.name}"
        action         = "accept"
        ruleset        = "LAN_IN"
        rule_index     = "40${value.id + 4}${index(var.vlans[key].networks-allow-from, group)}"
        protocol       = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall-groups[group].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall-groups[key].id]
      }
    ]
  ])
  firewall-rules-deny-to = flatten([
    for key, value in var.vlans : [
      for group in value.networks-deny-to : {
        key            = "lan-out-deny-${key}-to-${group}"
        name           = "Deny from ${value.name} to ${var.vlans[group].name}"
        action         = "drop"
        ruleset        = "LAN_OUT"
        rule_index     = "40${value.id + 2}${index(var.vlans[key].networks-deny-to, group)}"
        protocol       = "all"
        src_firewall_group_ids = [unifi_firewall_group.firewall-groups[key].id]
        dst_firewall_group_ids = [unifi_firewall_group.firewall-groups[group].id]
      }
    ]
  ])
  firewall-rules-deny-from = flatten([
    for key, value in var.vlans : [
      for group in value.networks-deny-from : {
        key            = "lan-in-deny-${group}-to-${key}"
        name           = "Deny from ${var.vlans[group].name} to ${value.name}"
        action         = "drop"
        ruleset        = "LAN_IN"
        rule_index     = "40${value.id + 1}${index(var.vlans[key].networks-deny-from, group)}"
        protocol       = "all"
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
  for_each = var.vlans
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
  for_each   = var.vlans
  name       = each.key
  type       = "address-group"
  members    = [each.value.cidr]
  depends_on = [unifi_network.vlans]
}

resource "unifi_firewall_rule" "vlan-firewall-rules" {
  for_each       = local.firewall-rules
  name           = each.value.name
  action         = each.value.action
  ruleset        = each.value.ruleset
  rule_index     = each.value.rule_index
  protocol       = each.value.protocol
  src_firewall_group_ids = each.value.src_firewall_group_ids
  dst_firewall_group_ids = each.value.dst_firewall_group_ids
}


