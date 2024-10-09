data "yandex_compute_image" "openvpn" {
 family = var.k8s_node_os_image
}
resource "yandex_compute_instance" "openvpn" {
 for_each = { for i in range(var.openvpn_count) : i => i }

 name = "openvpn-${each.key + 1}"
 platform_id = "standard-v1"
 zone = var.zones[each.key % length(var.zones)]
 resources {
  cores = var.k8s_node_cores
  memory = var.k8s_node_memory
  core_fraction = 20
 }
 boot_disk {
  initialize_params {
   image_id = data.yandex_compute_image.openvpn.image_id
   size = var.k8s_node_disk_size
   type = var.k8s_node_disk_type
  }
 }
 scheduling_policy {
  preemptible = true
 }
 network_interface {
  subnet_id = yandex_vpc_subnet.subnet[var.zones[each.key % length(var.zones)]].id
  nat = true
 }
 metadata = {
  ssh-keys = "root:${local.ssh-keys}"
  serial-port-enable = "1"
 }
}