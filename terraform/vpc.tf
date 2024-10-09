# Создание VPC

resource "yandex_vpc_network" "network" {
 folder_id = var.folder_id
 name = var.vpc_name
}

# Создание подсетей в цикле

resource "yandex_vpc_subnet" "subnet" {
 for_each = { for i, zone in var.zones : zone => zone }
 name   = "diploma-subnet-${index(var.zones, each.value) + 1}" 
 folder_id  = var.folder_id
 network_id  = yandex_vpc_network.network.id
 route_table_id = yandex_vpc_route_table.nat-route-table.id
 v4_cidr_blocks = [var.cidr_blocks[index(var.zones, each.value)]]
 zone = each.value 
}

# Создание публичной подсети

resource "yandex_vpc_subnet" "public-subnet" {
 name   = "public-subnet" 
 folder_id  = var.folder_id
 network_id  = yandex_vpc_network.network.id
 v4_cidr_blocks = var.public_cidr_blocks
 zone = "ru-central1-a"
}

# Создание таблицы маршрутизации

resource "yandex_vpc_route_table" "nat-route-table" {
  name = "nat-route-table"
  network_id = yandex_vpc_network.network.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address = "10.10.30.254"
  }
}