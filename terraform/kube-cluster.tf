locals {
  ssh-keys = fileexists("~/.ssh/id_ed25519.pub") ? file("~/.ssh/id_ed25519.pub") : var.ssh_public_key
  ssh-private-keys = fileexists("~/.ssh/id_ed25519") ? file("~/.ssh/id_ed25519") : var.ssh_private_key
}

data "yandex_compute_image" "master" {
  family = var.k8s_node_os_image
}
resource "yandex_compute_instance" "master" {
  name        = "master"
  platform_id = "standard-v1"
  count = var.master_count
  zone = var.zone-a
  resources {
    cores         = var.k8s_node_cores
    memory        = var.k8s_node_memory
    core_fraction = var.k8s_node_core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.master.image_id
	  size     = var.k8s_node_disk_size
      type     = var.k8s_node_disk_type
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.diploma-subnet-a.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${local.ssh-keys}"
    serial-port-enable = "1"
  }
}

data "yandex_compute_image" "worker" {
  family = var.k8s_node_os_image
}
resource "yandex_compute_instance" "worker" {
  name        = "worker-${count.index + 1}"
  platform_id = "standard-v1"
  count = var.worker_count
  zone = var.zone-b
  resources {
    cores         = var.k8s_node_cores
    memory        = var.k8s_node_memory
    core_fraction = var.k8s_node_core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.worker.image_id
	  size     = var.k8s_node_disk_size
      type     = var.k8s_node_disk_type
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.diploma-subnet-b.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${local.ssh-keys}"
    serial-port-enable = "1"
  }
}
