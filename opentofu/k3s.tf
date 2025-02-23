locals {
  k3s_install_command             = "curl -sfL https://get.k3s.io | K3S_TOKEN=${nonsensitive(random_password.k3s_secret.result)} K3S_KUBECONFIG_MODE=${var.k3s_config_mode} sh -s -"
  k3s_install_options             = "--tls-san=${var.k3s_controlplane_ip} --disable-cloud-controller --disable servicelb --disable local-storage  --disable traefik"
  bitwarden_age_keys_name_secrets = { for field in data.bitwarden_item_login.bitwarden_age_keys_name.field : field.name => field.text }
}

data "bitwarden_item_login" "github_pat" {
  search = var.bitwarden_github_pat_credentials_name
}

data "bitwarden_item_login" "age_keys" {
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
    ]
  }
}

# Create kubernetes secret for age private key using kubernetes provider
resource "kubernetes_secret" "age_keys" {
  metadata {
    name = "sops-age"
    namespace = "flux-system"
  }
  data = {
    "age.agekey" = base64encode(local.bitwarden_age_keys_name_secrets.private_key)
  }
}


resource "null_resource" "install_kubevip" {
  for_each   = try(null_resource.install_k3s["k8s-master-1"] != null ? toset(["k8s-master-1"]) : toset([]), toset([]))
  depends_on = [null_resource.install_k3s]

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual_machines["k8s-master-1"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f https://kube-vip.io/manifests/rbac.yaml",
      "sudo ctr image pull ghcr.io/kube-vip/kube-vip:latest; sudo ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:latest vip /kube-vip manifest daemonset --arp --interface eth0 --address ${var.k3s_controlplane_ip} --controlplane --inCluster --taint --leaderElection --services  | kubectl apply -f -",
      "kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml",
      "kubectl get configmap -n kube-system kubevip || kubectl create configmap -n kube-system kubevip --from-literal range-global=${var.k3s_loadbalancer_ip_range}"
    ]
  }
}

resource "null_resource" "join_k3s_nodes" {
  for_each   = { for vm in proxmox_virtual_environment_vm.virtual_machines : vm.name => vm if strcontains(lower(vm.name), "k8s") && !strcontains(lower(vm.name), "k8s-master-1") }
  depends_on = [null_resource.install_kubevip]

  connection {
    type        = "ssh"
    host        = split("/", each.value.initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "${local.k3s_install_command} ${strcontains(lower(each.value.name), "master") ? "server" : "agent"} --server https://${var.k3s_controlplane_ip}:6443 ${strcontains(lower(each.value.name), "master") ? local.k3s_install_options : ""}",
    ]
  }
}

resource "null_resource" "install_fluxcd" {
  for_each   = try(null_resource.install_k3s["k8s-master-1"] != null ? toset(["k8s-master-1"]) : toset([]), toset([]))
  depends_on = [null_resource.install_k3s]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual_machines["k8s-master-1"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh_credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh_credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl create namespace flux-system || true",
      "curl -s https://fluxcd.io/install.sh | sudo bash",
      "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && export GITHUB_TOKEN=${nonsensitive(data.bitwarden_item_login.github_pat.password)} && flux bootstrap github --owner=SurgeVortex --repository=starfleet-home-automation --branch=main --path=flux/clusters/isonet/flux-system --personal --interval=1m"
    ]
  }
}
