terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
  
  backend "s3" {
    endpoint = "https://storage.yandexcloud.net"
    bucket = "tfbucket"
    region = "ru-central1"
    key    = "tfbucket/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    }
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone-b
}