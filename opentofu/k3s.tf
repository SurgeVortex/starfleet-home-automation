locals {
  k3s-install-command = "curl -sfL https://get.k3s.io | sh -s -"
  k3s-install-options = "--tls-san=${var.k3s-controlplane-ip} --disable-cloud-controller --disable servicelb --disable local-storage  --disable traefik --node-name=$(hostname -f)"
}

resource "random_password" "k3s_secret" {
  length  = 16
  special = true
}

resource "null_resource" "install_k3s" {
  for_each   = try(proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"] != null ? toset(["k8s-master-1"]) : toset([]), toset([]))
  depends_on = [proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"]]

  triggers = {
    run_always = timestamp()
  }

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh-credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh-credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "export K3S_SECRET=${nonsensitive(random_password.k3s_secret.result)}",
      "export K3S_KUBECONFIG_MODE=${var.k3s-config-mode}",
      "${local.k3s-install-command} server --cluster-init ${local.k3s-install-options}",
    #   k3sup join --ip 192.168.1.22 --server --server-ip 192.168.1.20 --server-user dmistry --sudo --k3s-extra-args "--disable traefik  --disable servicelb --node-ip=192.168.1.22"
    ]
  }
}


resource "null_resource" "install_kubevip" {
  for_each   = try(null_resource.install_k3s["k8s-master-1"] != null ? toset(["k8s-master-1"]) : toset([]), toset([]))
  depends_on = [null_resource.install_k3s]

  triggers = {
    run_always = timestamp()
  }

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = nonsensitive(data.bitwarden_item_login.ssh-credentials.username)
    private_key = nonsensitive(data.bitwarden_item_login.ssh-credentials.notes)
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f https://kube-vip.io/manifests/rbac.yaml",
      "alias kube-vip='ctr image pull ghcr.io/kube-vip/kube-vip:latest; ctr run --rm --net-host docker.io/plndr/kube-vip:latest vip /kube-vip'",
      "sudo kube-vip manifest daemonset --arp --interface eth0 --address ${var.k3s-controlplane-ip} --controlplane --inCluster --taint --leaderElection --services  | kubectl apply -f -",
      "kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml",
      "kubectl get configmap -n kube-system kubevip || kubectl create configmap -n kube-system kubevip --from-literal range-global=${var.k3s-loadbalancer-ip-range}"
    ]
  }
}

# resource "null_resource" "join_k3s_nodes" {
#   for_each   = { for vm in proxmox_virtual_environment_vm.virtual-machines: vm.name => vm if strcontains(lower(vm.name), "k8s") && !strcontains(lower(vm.name), "k8s-master-1") }

#   depends_on = [null_resource.install_kubevip]

#   connection {
#     type        = "ssh"
#     host        = split("/", each.value.initialization[0].ip_config[0].ipv4[0].address)[0]
#     user        = nonsensitive(data.bitwarden_item_login.ssh-credentials.username)
#     private_key = nonsensitive(data.bitwarden_item_login.ssh-credentials.notes)
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "export K3S_SECRET=${nonsensitive(random_password.k3s_secret.result)}",
#       "export K3S_KUBECONFIG_MODE=${var.k3s-config-mode}",
#       "${local.k3s-install-command} ${strcontains(lower(each.value.name), "master") ? "server" : "agent"} --server https://${var.k3s-controlplane-ip}:6443",
#     ]
#   }
# }

# resource "null_resource" "install_fluxcd" {
#   depends_on = [null_resource.join_k3s_nodes]

#   provisioner "local-exec" {
#     command = <<EOT
#             kubectl create namespace flux-system
#             curl -s https://fluxcd.io/install.sh | sudo bash
#             flux install --namespace=flux-system --network-policy=false

#             # Configure Flux to sync with your Git repository
#             flux create source git my-repo \
#                 --url=https://github.com/your-username/your-repo \
#                 --branch=main \
#                 --interval=1m

#             flux create kustomization my-kustomization \
#                 --target-namespace=default \
#                 --source=GitRepository/my-repo \
#                 --path="./path/to/your/manifests" \
#                 --prune=true \
#                 --interval=10m
#         EOT
#   }
# }
