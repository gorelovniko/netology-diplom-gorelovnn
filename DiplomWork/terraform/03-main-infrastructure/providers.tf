#========================= Провайдер для terraform ==========================

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      # version = "0.129.0"
    }
  }

  required_version = ">=1.8.4"

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket     = "tf-state-gorelovnn"  # замените на ваш bucket
    key        = "terraform.tfstate"
    region     = "ru-central1"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true


    sts_endpoint = null
  }

}

provider "yandex" {
  # token                  = "do not use!!!"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  # service_account_key_file = file("../authorized_key.json")
  service_account_key_file = var.authorized_key
}