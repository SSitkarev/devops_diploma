# Создание сервисного аккаунта для Terraform

resource "yandex_iam_service_account" "service" {
  folder_id = var.folder_id
  name      = var.account_name
}

# Назначение роли editor сервисному аккаунту

resource "yandex_resourcemanager_folder_iam_member" "service_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"
}

# Создание статического ключа для сервисного аккаунта

resource "yandex_iam_service_account_static_access_key" "terraform_service_account_key" {
  service_account_id = yandex_iam_service_account.service.id
}

# Создание bucket

resource "yandex_storage_bucket" "tfbucket" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.secret_key
  force_destroy = true
  
# Экспорт идентификатора ключа и секретного ключа
 
provisioner "local-exec" {
  command = "echo ACCESS_KEY=${yandex_iam_service_account_static_access_key.terraform_service_account_key.access_key} >> s3keys"
}

provisioner "local-exec" {
  command = "echo SECRET_KEY=${yandex_iam_service_account_static_access_key.terraform_service_account_key.secret_key} >> s3keys"
}
}