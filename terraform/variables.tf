###cloud vars

variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "account_name" {
  type        = string
  default     = "service"
}

variable "bucket_name" {
  type        = string
  default     = "tfbucket"
}

variable "vpc_name" {
  type        = string
  default     = "diploma-network"
}

variable "subnet-a" {
  type        = string
  default     = "diploma-subnet-a"
}

variable "subnet-b" {
  type        = string
  default     = "diploma-subnet-b"
}

variable "zone-a" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "zone-b" {
  type        = string
  default     = "ru-central1-b"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "cidr-1" {
  type        = list(string)
  default     = ["10.10.10.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "cidr-2" {
  type        = list(string)
  default     = ["10.10.20.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}