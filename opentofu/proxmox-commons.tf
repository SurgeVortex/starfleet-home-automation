locals {
  ssh-credentials-secrets = { for field in data.bitwarden_item_login.ssh-credentials.field : field.name => field.text }
  bw-api-credentials-secrets = { for field in data.bitwarden_item_login.bitwarden-api-credentials.field : field.name => field.text }
}

data "bitwarden_item_login" "proxmox-credentials" {
  search = var.proxmox-credentials-name
}

data "bitwarden_item_login" "ssh-credentials" {
  search = var.ssh-credentials-name
}

data "bitwarden_item_login" "bitwarden-api-credentials" {
  search = var.bitwarden-api-credentials-name
}

resource "proxmox_virtual_environment_cluster_options" "options" {
  language   = "en"
  keyboard   = "en-us"
  email_from = "proxmox-root@isonet.casa"
}

resource "proxmox_virtual_environment_download_file" "cloud_images" {
  for_each     = var.proxmox-cloud-images
  content_type = each.value.content_type
  datastore_id = each.value.datastore_id
  node_name    = each.value.node_name
  file_name    = "${each.key}.img"
  url          = each.value.url
}

resource "proxmox_virtual_environment_vm" "virtual-machines" {
  for_each  = var.proxmox-vms
  name      = each.key
  node_name = each.value.node_name
  bios      = try(each.value.bios, "seabios")
  cpu {
    architecture = try(each.value.cpu.architecture, "x86_64")
    cores        = 4
    sockets      = 1
  }
  description = each.value.description
  dynamic "disk" {
    for_each = each.value.disk
    content {
      backup       = disk.value.backup
      datastore_id = disk.value.datastore_id
      file_id      = each.value.is_cloud_init ? proxmox_virtual_environment_download_file.cloud_images[disk.value.file_id].id : disk.value.file_id
      interface    = disk.value.interface
      size         = disk.value.size
    }
  }
  dynamic "efi_disk" {
    for_each = each.value.efi_disk != null ? [each.value.efi_disk] : []
    content {


      datastore_id      = efi_disk.datastore_id
      file_format       = efi_disk.file_format
      type              = efi_disk.type
      pre_enrolled_keys = efi_disk.pre_enrolled_keys
    }
  }
  dynamic "tpm_state" {
    for_each = each.value.tpm_state != null ? [each.value.tpm_state] : []
    content {


      datastore_id = each.value.tpm_state.datastore_id
      version      = each.value.tpm_state.version
    }
  }
  dynamic "initialization" {
    for_each = each.value.initialization != null ? { init = true } : each.value.is_cloud_init ? { cloud_init = true } : {}
    content {
      datastore_id = try(each.value.initialization.datastore_id != null ? each.value.initialization.datastore_id : "local-zfs", "local-zfs")
      interface    = try(each.value.initialization.interface != null ? each.value.initialization.interface : "ide2", "ide2")
      dynamic "dns" {
        for_each = try(each.value.initialization.dns != null ? each.value.initialization : [], [])
        content {
          servers = dns.servers
        }
      }
      ip_config {
        ipv4 {
          address = try(each.value.initialization.ip_config.ipv4.address != null ? each.value.initialization.ip_config.ipv4.address : "dhcp", "dhcp")
          gateway = try(each.value.initialization.ip_config.ipv4.gateway, null)
        }
      }
      dynamic "user_account" {
        for_each = each.value.is_cloud_init ? ["cloud_init"] : each.value.initialization.user_account != null ? ["user_account"] : []
        content {
          keys     = each.value.is_cloud_init ? [local.ssh-credentials-secrets.ssh-public-key] : each.value.initialization.user_account.keys
          username = each.value.is_cloud_init ? data.bitwarden_item_login.ssh-credentials.username : each.value.initialization.user_account.username
          password = each.value.is_cloud_init ? data.bitwarden_item_login.ssh-credentials.password : each.value.initialization.user_account.password
        }
      }
    }
  }
  keyboard_layout = try(each.value.keyboard_layout, "en-us")
  memory {
    dedicated = each.value.memory.dedicated
    floating  = each.value.memory.floating
    shared    = each.value.memory.shared
  }
  dynamic "network_device" {
    for_each = each.value.network_device
    content {
      bridge  = try(network_device.value.bridge, "vmbr0")
      model   = try(network_device.value.model, "virtio")
      vlan_id = try(network_device.value.vlan_id, "40")
    }
  }
  on_boot = each.value.on_boot
  operating_system {
    type = try(each.value.operating_system.type, "l26")
  }
  pool_id = each.value.pool_id
  started = each.value.started
  dynamic "startup" {
    for_each = each.value.startup != null ? [each.value.startup] : []
    content {
      order = startup.value.order
    }
  }
  vm_id = each.value.vm_id
}

resource "null_resource" "setup_bastion" {
  for_each = try(proxmox_virtual_environment_vm.virtual-machines["bastion"] != null ? { bastion : "bastion" } : {}, {})
  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual-machines["bastion"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = data.bitwarden_item_login.ssh-credentials.username
    private_key = data.bitwarden_item_login.ssh-credentials.notes

  }
  triggers = {
    script_checksum = md5(file("${path.module}/scripts/bastion-setup.sh"))
  }
  provisioner "file" {
    source      = "${path.module}/scripts/bastion-setup.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "if ! grep -q 'BW_EMAIL' ~/.profile; then echo 'export BW_EMAIL=${data.bitwarden_item_login.bitwarden-api-credentials.username}' >> ~/.profile; fi",
      "if ! grep -q 'BW_MASTER_PASSWORD' ~/.profile; then echo 'export BW_MASTER_PASSWORD=${data.bitwarden_item_login.bitwarden-api-credentials.password}' >> ~/.profile; fi",
      "if ! grep -q 'BW_CLIENTID' ~/.profile; then echo 'export BW_CLIENTID=${local.bw-api-credentials-secrets.client-id}' >> ~/.profile; fi",
      "if ! grep -q 'BW_CLIENTSECRET' ~/.profile; then echo 'export BW_CLIENTSECRET=${local.bw-api-credentials-secrets.client-secret}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_TENANT_ID' ~/.profile; then echo 'export AZURE_TENANT_ID=${var.azure-state-storage-tenant-id}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_CLIENT_ID' ~/.profile; then echo 'export AZURE_CLIENT_ID=${var.azure-state-storage-client-id}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_CLIENT_SECRET' ~/.profile; then echo 'export AZURE_CLIENT_SECRET=${var.azure-state-storage-client-secret}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_SUBSCRIPTION_ID' ~/.profile; then echo 'export AZURE_SUBSCRIPTION_ID=${var.azure-state-storage-subscription-id}' >> ~/.profile; fi",
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh args",
    ]
  }
}
