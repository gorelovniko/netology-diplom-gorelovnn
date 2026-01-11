# terraform {
#   backend "s3" {
#     endpoints = {
#       s3 = "https://storage.yandexcloud.net"
#     }
#     bucket     = "tf-state-gorelovnn"  # замените на ваш bucket
#     key        = "terraform.tfstate"
#     region     = "ru-central1"
#     skip_region_validation      = true
#     skip_credentials_validation = true
#     # force_path_style            = true
#   }

#   # required_providers {
#   #   yandex = {
#   #     #  source  = "yandex-cloud/yandex"
#   #     #  version = "~> 0.90"
#   #      service_account_key_file = file("../authorized_key.json")
#   #   }
#   # }

# #   required_providers "yandex" {
# #   service_account_key_file = file("../authorized_key.json")
# #   cloud_id                 = "your-cloud-id"
# #   folder_id                = "your-folder-id"
# #   zone                     = "ru-central1-a"
# # }
# }

# # provider "yandex" {
# #   # token                  = "do not use!!!"
# #   cloud_id                 = var.cloud_id
# #   folder_id                = var.folder_id
# #   service_account_key_file = file("../authorized_key.json")
# # }