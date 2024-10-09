resource "yandex_compute_instance" "nat-instance" {
  name     = "nat-instance"
  zone     = "ru-central1-a"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id    = "fd8moeaar19homgk3vsm"
      name        = "nat-instance"
      type        = "network-nvme"
      size        = "20"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public-subnet.id
    ip_address = "10.10.30.254"
    nat       = true
  }
 metadata = {
  ssh-keys = "root:${local.ssh-keys}"
  serial-port-enable = "1"
 }
}
