resource "random_password" "k3s_secret" {
  length  = 16
  special = true
}

resource "null_resource" "install_k3s" {
  for_each   = try(proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"] != null ? toset(["k8s-master-1"]) : toset([]), toset([]))
  depends_on = [proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"]]

  triggers = {
    run-resource = var.trigger-k3s-install
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
      "curl -sfL https://get.k3s.io | sh -s - server --cluster-init --tls-san=${var.k3s-controlplane-ip} --disable-cloud-controller --disable servicelb --disable local-storage  --disable traefik --node-name=$(hostname -f)"
    ]
  }
}

resource "null_resource" "install_kubevip" {
  for_each   = try(null_resource.install_k3s["k8s-master-1"] != null ? toset(["k8s-master-1"]) : toset([]), toset([]))
  depends_on = [null_resource.install_k3s]

  triggers = {
    run-resource = var.trigger-k3s-install
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
      "alias kube-vip='ctr run --rm --net-host docker.io/plndr/kube-vip:latest vip /kube-vip'",
      "sudo kube-vip manifest daemonset --arp --interface eth0 --address ${var.k3s-controlplane-ip} --controlplane --inCluster --taint --leaderElection --services  | kubectl apply -f -",
      "kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml",
      "kubectl create configmap -n kube-system kubevip --from-literal range-global=${var.k3s-loadbalancer-ip-range}"
    ]
  }
}

# resource "null_resource" "join_k3s_nodes" {
#   for_each   = { for vm in proxmox_virtual_environment_vm.virtual-machines: vm.name => vm if contains(lower(vm.name), "k8s") && !contains(lower(vm.name), "k8s-master-1") }

#   depends_on = [null_resource.install_kubevip]

#   connection {
#     type        = "ssh"
#     host        = split("/", each.value.initialization[0].ip_config[0].ipv4[0].address)[0]
#     user        = nonsensitive(data.bitwarden_item_login.ssh-credentials.username)
#     private_key = nonsensitive(data.bitwarden_item_login.ssh-credentials.notes)
#   }

#   provisioner "remote-exec" {
#     inline = [
#             if [[ "${proxmox_vm_qemu.k3s_nodes[count.index].name}" == *"master"* ]]; then
#                 curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_SECRET} sh -s - server --server ${K3S_URL}
#             else
#                 curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_SECRET} sh -s - agent --server ${K3S_URL}
#             fi
#      ]
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
