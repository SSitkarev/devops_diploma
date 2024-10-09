resource "yandex_lb_target_group" "master-lg" {
  name       = "master-lg"
  depends_on = [yandex_compute_instance.master]
  dynamic "target" {
    for_each = yandex_compute_instance.master
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "master-lb" {
  name = "master-lb"
  listener {
    name = "ssh"
    port = 22
	protocol = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.master-lg.id
    healthcheck {
      name = "healthcheck"
      tcp_options {
        port = 22
      }
    }
  }
  depends_on = [yandex_lb_target_group.master-lg]
}

resource "yandex_lb_target_group" "worker-lg" {
  name       = "worker-lg"
  depends_on = [yandex_compute_instance.worker]
  dynamic "target" {
    for_each = yandex_compute_instance.worker
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "worker-lb" {
  name = "worker-lb"
  listener {
    name = "ssh"
    port = 22
	protocol = "tcp"
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.worker-lg.id
    healthcheck {
      name = "healthcheck"
      tcp_options {
        port = 22
      }
    }
  }
  depends_on = [yandex_lb_target_group.worker-lg]
}