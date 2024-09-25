# Создание bucket

resource "yandex_storage_bucket" "tfbucket" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.secret_key
  force_destroy = true
}