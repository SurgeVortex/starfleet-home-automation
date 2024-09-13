resource "random_password" "k3s_secret" {
  length  = 16
  special = true
}

resource "null_resource" "install_k3s" {
  depends_on = [proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"]]

  triggers = {
    run-resource = var.trigger-k3s-install
  }

  connection {
    type        = "ssh"
    host        = split("/", proxmox_virtual_environment_vm.virtual-machines["k8s-master-1"].initialization[0].ip_config[0].ipv4[0].address)[0]
    user        = data.bitwarden_item_login.ssh-credentials.username
    private_key = data.bitwarden_item_login.ssh-credentials.notes
  }

  provisioner "remote-exec" {
    inline = [
      "export K3S_SECRET=${random_password.k3s_secret.result}",
      "export K3S_KUBECONFIG_MODE=${var.k3s-config-mode}",
      "curl -sfL https://get.k3s.io | sh -s - server --cluster-init --tls-san ${var.k3s-controlplane-ip} --disable-cloud-controller --disable servicelb --disable local-storage  --disable traefik --node-name=$(hostname -f)"
    ]
  }
}

resource "null_resource" "install_kubevip" {
  depends_on = [null_resource.install_k3s]

  provisioner "local-exec" {
    command = <<EOT
            K3S_NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
            kubectl label node $K3S_NODE kube-vip.io/egress=true
            kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
            alias kube-vip="docker run --network host --rm plndr/kube-vip:0.3.7"
            kube-vip manifest daemonset \
                --arp \
                --interface eth0 \
                --address 192.168.0.100 \
                --controlplane \
                --services \
                --leaderElection | kubectl apply -f -
        EOT
  }
}

# resource "null_resource" "join_k3s_nodes" {
#   count = length(proxmox_vm_qemu.k3s_nodes)

#   depends_on = [null_resource.install_kubevip]

#   provisioner "local-exec" {
#     environment = {
#       K3S_SECRET = random_password.k3s_secret.result
#       K3S_URL    = "https://${proxmox_vm_qemu.k3s-master-1.network_interface[0].ip_address}:6443"
#     }

#     command = <<EOT
#             if [[ "${proxmox_vm_qemu.k3s_nodes[count.index].name}" == *"master"* ]]; then
#                 curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_SECRET} sh -s - server --server ${K3S_URL}
#             else
#                 curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_SECRET} sh -s - agent --server ${K3S_URL}
#             fi
#         EOT
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
