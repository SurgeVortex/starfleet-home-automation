locals {
  k3s_install_command             = "curl -sfL https://get.k3s.io | K3S_TOKEN=${nonsensitive(random_password.k3s_secret.result)} K3S_KUBECONFIG_MODE=${var.k3s_config_mode} sh -s -"
  k3s_install_options             = "--tls-san=${var.haproxy_vip} --disable-cloud-controller --disable servicelb --disable local-storage  --disable traefik"
  bitwarden_age_keys_name_secrets = { for field in data.bitwarden_item_secure_note.age_keys.field : field.name => field.text }
}

data "bitwarden_item_login" "github_pat" {
  search = var.bitwarden_github_pat_credentials_name
}

data "bitwarden_item_secure_note" "age_keys" {
  search = var.bitwarden_age_keys_name
}

resource "random_password" "k3s_secret" {
  length  = 32
  special = false
}

resource "null_resource" "install_k3s" {
  for_each   = try(proxmox_virtual_environment_vm.virtual_machines["k8s-master-1"] != null ? toset(["k8s-master-1"]) : toset([]), toset([]))
  depends_on = [proxmox_virtual_environment_vm.virtual_machines["k8s-master-1"]]

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual_machines["k8s-master-1"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "${local.k3s_install_command} server --cluster-init ${local.k3s_install_options}",
    ]
  }
}

resource "null_resource" "copy_kubeconfig" {
  for_each   = try(proxmox_virtual_environment_vm.virtual_machines["bastion"] != null ? toset(["bastion"]) : toset([]), toset([]))
  depends_on = [null_resource.install_k3s]

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual_machines["bastion"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "scp -o StrictHostKeyChecking=no ${nonsensitive(data.bitwarden_item_login.ssh_credentials.username)}@${split("/", proxmox_virtual_environment_vm.virtual_machines["k8s-master-1"].initialization[0].ip_config[0].ipv4[0].address)[0]}:/etc/rancher/k3s/k3s.yaml /tmp/k3s.yaml",
      "mkdir -p ~/.kube",
      "mv /tmp/k3s.yaml ~/.kube/config",
      "sed -i 's/127.0.0.1/${var.haproxy_vip}/g' ~/.kube/config",
    ]
  }
}

resource "null_resource" "kubernetes_secret_age_keys" {
  for_each   = try(proxmox_virtual_environment_vm.virtual_machines["bastion"] != null ? toset(["bastion"]) : toset([]), toset([]))
  depends_on = [null_resource.copy_kubeconfig]

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual_machines["bastion"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl create ns flux-system",
      "echo \"kubectl --namespace=flux-system create secret generic sops-age --from-literal=age.agekey=${nonsensitive(local.bitwarden_age_keys_name_secrets.private-key)}\"",
      "kubectl --namespace=flux-system create secret generic sops-age --from-literal=age.agekey=${nonsensitive(local.bitwarden_age_keys_name_secrets.private-key)}"
    ]
  }
}

resource "null_resource" "join_k3s_nodes" {
  for_each   = { for vm in proxmox_virtual_environment_vm.virtual_machines : vm.name => vm if strcontains(lower(vm.name), "k8s") && !strcontains(lower(vm.name), "k8s-master-1") }
  depends_on = [null_resource.install_k3s]
  connection {
    type        = "ssh"
    host        = split("/", each.value.initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "${local.k3s_install_command} ${strcontains(lower(each.value.name), "master") ? "server" : "agent"} --server https://${var.haproxy_vip}:6443 ${strcontains(lower(each.value.name), "master") ? local.k3s_install_options : ""}",
    ]
  }
}

resource "null_resource" "install_fluxcd" {
  for_each   = try(proxmox_virtual_environment_vm.virtual_machines["bastion"] != null ? toset(["bastion"]) : toset([]), toset([]))
  depends_on = [null_resource.copy_kubeconfig]

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual_machines["bastion"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl create namespace flux-system || true",
      "curl -s https://fluxcd.io/install.sh | sudo bash",
      "export GITHUB_TOKEN=${nonsensitive(data.bitwarden_item_login.github_pat.password)} && flux bootstrap github --owner=SurgeVortex --repository=starfleet-home-automation --branch=main --path=flux/clusters/isonet --personal --interval=1m"
    ]
  }
}
