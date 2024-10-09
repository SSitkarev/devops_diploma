locals {
  ssh-keys = fileexists("~/.ssh/id_ed25519.pub") ? file("~/.ssh/id_ed25519.pub") : var.ssh_public_key
  ssh-private-keys = fileexists("~/.ssh/id_ed25519") ? file("~/.ssh/id_ed25519") : var.ssh_private_key
}

data "yandex_compute_image" "master" {
 family = var.k8s_node_os_image
}
resource "yandex_compute_instance" "master" {
 for_each = { for i in range(var.master_count) : i => i }

 name = "master-${each.key + 1}"
 platform_id = "standard-v1"
 zone = var.zones[each.key % length(var.zones)]
 resources {
  cores = var.k8s_node_cores
  memory = var.k8s_node_memory
  core_fraction = var.k8s_node_core_fraction
 }
 boot_disk {
  initialize_params {
   image_id = data.yandex_compute_image.master.image_id
   size = var.k8s_node_disk_size
   type = var.k8s_node_disk_type
  }
 }
 scheduling_policy {
  preemptible = true
 }
 network_interface {
  subnet_id = yandex_vpc_subnet.subnet[var.zones[each.key % length(var.zones)]].id
#  nat = true
 }
 metadata = {
  user-data = data.template_file.cloud-init.rendered
  ssh-keys = "root:${local.ssh-keys}"
  serial-port-enable = "1"
 }
}

data "yandex_compute_image" "worker" {
 family = var.k8s_node_os_image
}
resource "yandex_compute_instance" "worker" {
 for_each = { for i in range(var.worker_count) : i => i }

 name = "worker-${each.key + 1}"
 platform_id = "standard-v1"
 zone = var.zones[each.key % length(var.zones)]
 resources {
  cores = var.k8s_node_cores
  memory = var.k8s_node_memory
  core_fraction = var.k8s_node_core_fraction
 }
 boot_disk {
  initialize_params {
   image_id = data.yandex_compute_image.worker.image_id
   size = var.k8s_node_disk_size
   type = var.k8s_node_disk_type
  }
 }
 scheduling_policy {
  preemptible = true
 }
 network_interface {
  subnet_id = yandex_vpc_subnet.subnet[var.zones[each.key % length(var.zones)]].id
#  nat = true
 }
 metadata = {
  user-data = data.template_file.cloud-init.rendered
  ssh-keys = "root:${local.ssh-keys}"
  serial-port-enable = "1"
 }
}