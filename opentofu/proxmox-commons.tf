locals {
  ssh_credentials_secrets    = { for field in data.bitwarden_item_login.ssh_credentials.field : field.name => field.text }
  bw_api_credentials_secrets = { for field in data.bitwarden_item_login.bitwarden_api_credentials.field : field.name => field.text }
}

data "bitwarden_item_login" "proxmox_credentials" {
  search = var.proxmox_credentials_name
}

data "bitwarden_item_login" "ssh_credentials" {
  search = var.ssh_credentials_name
}

data "bitwarden_item_login" "bitwarden_api_credentials" {
  search = var.bitwarden_api_credentials_name
}

resource "proxmox_virtual_environment_cluster_options" "options" {
  language   = "en"
  keyboard   = "en-us"
  email_from = "proxmox-root@isonet.casa"
}

resource "proxmox_virtual_environment_download_file" "cloud_images" {
  for_each     = var.proxmox_cloud_images
  content_type = each.value.content_type
  datastore_id = each.value.datastore_id
  node_name    = each.value.node_name
  file_name    = each.value.file_name
  url          = each.value.url
}

resource "proxmox_virtual_environment_vm" "virtual_machines" {
  for_each  = var.proxmox_vms
  name      = each.key
  node_name = each.value.node_name
  bios      = try(each.value.bios, "seabios")
  cpu {
    architecture = try(each.value.cpu.architecture, "x86_64")
    cores        = try(each.value.cpu.cores, 4)
    sockets      = try(each.value.cpu.sockets, 1)
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
          keys     = each.value.is_cloud_init ? [local.ssh_credentials_secrets.ssh-public-key] : each.value.initialization.user_account.keys
          username = each.value.is_cloud_init ? data.bitwarden_item_login.ssh_credentials.username : each.value.initialization.user_account.username
          password = each.value.is_cloud_init ? data.bitwarden_item_login.ssh_credentials.password : each.value.initialization.user_account.password
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

resource "proxmox_virtual_environment_container" "containers" {
  for_each  = var.proxmox_containers
  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  cpu {
    architecture = try(each.value.cpu.architecture, "amd64")
    cores        = try(each.value.cpu.cores, 1)
  }

  description = each.value.description

  disk {
    datastore_id = try(each.value.disk.datastore_id, "local")
    size         = try(each.value.disk.size, 4)
  }

  dynamic "initialization" {
    for_each = each.value.initialization != null ? { init = true } : each.value.is_cloud_init ? { cloud_init = true } : {}
    content {
      dynamic "dns" {
        for_each = try(each.value.initialization.dns != null ? each.value.initialization : [], [])
        content {
          domain  = try(each.value.initialization.dns.domain, null)
          servers = try(each.value.initialization.dns.servers, [])
        }
      }
      hostname = try(each.value.initialization.hostname, null)
      ip_config {
        ipv4 {
          address = try(each.value.initialization.ip_config.ipv4.address, null)
          gateway = try(each.value.initialization.ip_config.ipv4.gateway, null)
        }
      }
      dynamic "user_account" {
        for_each = each.value.is_cloud_init ? ["cloud_init"] : each.value.initialization.user_account != null ? ["user_account"] : []
        content {
          keys     = each.value.is_cloud_init ? [local.ssh_credentials_secrets.ssh-public-key] : each.value.initialization.user_account.keys
          password = each.value.is_cloud_init ? data.bitwarden_item_login.ssh_credentials.password : each.value.initialization.user_account.password
        }
      }
    }
  }

  memory {
    dedicated = try(each.value.memory.dedicated, 512)
    swap      = try(each.value.memory.swap, 0)
  }

  dynamic "network_interface" {
    for_each = try(each.value.network_interface, [])
    content {
      bridge  = try(network_interface.value.bridge, "vmbr0")
      name    = network_interface.value.name
      vlan_id = try(network_interface.value.vlan_id, null)
    }
  }

  operating_system {
    template_file_id = each.value.is_cloud_init ? proxmox_virtual_environment_download_file.cloud_images[each.value.operating_system.template_file_id].id : each.value.operating_system.template_file_id
    type             = try(each.value.operating_system.type, "unmanaged")
  }

  pool_id       = each.value.pool_id
  started       = try(each.value.started, true)
  start_on_boot = try(each.value.start_on_boot, true)
  unprivileged  = try(each.value.unprivileged, false)

  dynamic "startup" {
    for_each = each.value.startup != null ? [each.value.startup] : []
    content {
      order = startup.value.order
    }
  }
  features {
    nesting = true
  }
  depends_on = [proxmox_virtual_environment_download_file.cloud_images]
}

resource "null_resource" "setup_bastion" {
  for_each = try(proxmox_virtual_environment_vm.virtual_machines["bastion"] != null ? { bastion : "bastion" } : {}, {})
  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual_machines["bastion"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = data.bitwarden_item_login.ssh_credentials.username
    private_key = data.bitwarden_item_login.ssh_credentials.notes

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
      "if [ ! -f ~/.ssh/id_rsa ]; then echo '${nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)}' > ~/.ssh/id_rsa; chmod 600 ~/.ssh/id_rsa; fi",
      "if [ ! -f ~/.ssh/id_rsa.pub ]; then echo '${nonsensitive(local.ssh_credentials_secrets.ssh-public-key)}' > ~/.ssh/id_rsa.pub; chmod 644 ~/.ssh/id_rsa.pub; fi",
      "if ! grep -q 'BW_EMAIL' ~/.profile; then echo 'export BW_EMAIL=${data.bitwarden_item_login.bitwarden_api_credentials.username}' >> ~/.profile; fi",
      "if ! grep -q 'BW_MASTER_PASSWORD' ~/.profile; then echo 'export BW_MASTER_PASSWORD=${replace(nonsensitive(data.bitwarden_item_login.bitwarden_api_credentials.password), "$", "\\$")}' >> ~/.profile; fi",
      "if ! grep -q 'BW_CLIENTID' ~/.profile; then echo 'export BW_CLIENTID=${nonsensitive(local.bw_api_credentials_secrets.client-id)}' >> ~/.profile; fi",
      "if ! grep -q 'BW_CLIENTSECRET' ~/.profile; then echo 'export BW_CLIENTSECRET=${nonsensitive(local.bw_api_credentials_secrets.client-secret)}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_TENANT_ID' ~/.profile; then echo 'export AZURE_TENANT_ID=${var.azure_state_storage_tenant_id}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_CLIENT_ID' ~/.profile; then echo 'export AZURE_CLIENT_ID=${var.azure_state_storage_client_id}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_CLIENT_SECRET' ~/.profile; then echo 'export AZURE_CLIENT_SECRET=${var.azure_state_storage_client_secret}' >> ~/.profile; fi",
      "if ! grep -q 'AZURE_SUBSCRIPTION_ID' ~/.profile; then echo 'export AZURE_SUBSCRIPTION_ID=${var.azure_state_storage_subscription_id}' >> ~/.profile; fi",
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh args",
    ]
  }
}

resource "random_string" "keepalived_auth_pass" {
  length  = 16
  special = false
}

resource "null_resource" "setup_haproxy" {
  for_each = { for k, v in proxmox_virtual_environment_container.containers : k => v if startswith(k, "haproxy") }
  connection {
    type        = "ssh"
    host        = split("/", each.value.initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = "root"
    private_key = data.bitwarden_item_login.ssh_credentials.notes
  }

  triggers = {
    script_checksum = md5(file("${path.module}/scripts/acme_setup.sh"))
    haproxy_cfg_checksum = md5(templatefile("templates/haproxy.cfg.tmpl", {
      worker_backends = [
        for k, v in proxmox_virtual_environment_vm.virtual_machines :
        {
          name = k, ip = split("/", v.initialization[0].ip_config[0].ipv4[0].address)[0]
        } if startswith(k, "k8s-worker")
      ],
      master_backends = [
        for k, v in proxmox_virtual_environment_vm.virtual_machines :
        {
          name = k, ip = split("/", v.initialization[0].ip_config[0].ipv4[0].address)[0]
        } if startswith(k, "k8s-master")
      ],
      vip         = var.haproxy_vip,
      domain_name = var.haproxy_domain
    }))
    keepalived_cfg_checksum = md5(templatefile("templates/keepalived.conf.tmpl", {
      keepalived_priority  = try(each.value.priority, 100),
      keepalived_auth_pass = random_string.keepalived_auth_pass.result,
      vip                  = var.haproxy_vip,
    }))
    haproxy_vip          = var.haproxy_vip
    haproxy_domain       = var.haproxy_domain
    cloudflare_api_token = var.cloudflare_api_token
  }

  provisioner "remote-exec" {
    inline = [
      "apt update && apt install -y haproxy keepalived socat libapache2-mod-security2 curl jq",
    ]
  }

  provisioner "file" {
    content = templatefile("templates/keepalived.conf.tmpl", {
      keepalived_priority  = try(each.value.priority, 100),
      keepalived_auth_pass = random_string.keepalived_auth_pass.result,
      vip                  = var.haproxy_vip,
    })
    destination = "/etc/keepalived/keepalived.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/acme_setup.sh"
    destination = "/tmp/acme_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl enable --now keepalived",
      "systemctl restart keepalived",
      "sleep 5",
      "chmod +x /tmp/acme_setup.sh",
      "/tmp/acme_setup.sh ${var.haproxy_domain} ${var.cloudflare_api_token}"
    ]
  }

  provisioner "file" {
    content = templatefile("templates/haproxy.cfg.tmpl", {
      worker_backends = [
        for k, v in proxmox_virtual_environment_vm.virtual_machines :
        {
          name = k, ip = split("/", v.initialization[0].ip_config[0].ipv4[0].address)[0]
        } if startswith(k, "k8s-worker")
      ],
      master_backends = [
        for k, v in proxmox_virtual_environment_vm.virtual_machines :
        {
          name = k, ip = split("/", v.initialization[0].ip_config[0].ipv4[0].address)[0]
        } if startswith(k, "k8s-master")
      ],
      vip         = var.haproxy_vip,
      domain_name = var.haproxy_domain
    })
    destination = "/etc/haproxy/haproxy.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf",
      "echo \"SecRuleEngine On\" >> /etc/modsecurity/modsecurity.conf",
      "curl https://www.cloudflare.com/ips-v4 -o /etc/haproxy/cloudflare_ips",
      "systemctl enable --now haproxy",
      "systemctl restart haproxy",
    ]
  }

}
