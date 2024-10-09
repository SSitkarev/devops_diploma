resource "local_file" "kubespray-inventory" {
  content  = templatefile("${path.module}/inventory.tftpl", {
    masters = yandex_compute_instance.master
    workers = yandex_compute_instance.worker
  })
  filename = "kubespray/inventory/k8scluster/inventory.yaml"
}

data "template_file" "cloud-init" {
 template = file("${path.module}/cloud-init.yml")
 vars = {
   ssh_public_key = local.ssh-keys
   ssh_private_key = local.ssh-private-keys
 }
}