resource "yandex_vpc_network" "diploma-network" {
  name = var.vpc_name
}
resource "yandex_vpc_subnet" "diploma-subnet-a" {
  name           = var.subnet-a
  zone           = var.zone-a
  network_id     = yandex_vpc_network.diploma-network.id
  v4_cidr_blocks = var.cidr-1
}

resource "yandex_vpc_subnet" "diploma-subnet-b" {
  name           = var.subnet-b
  zone           = var.zone-b
  network_id     = yandex_vpc_network.diploma-network.id
  v4_cidr_blocks = var.cidr-2
}