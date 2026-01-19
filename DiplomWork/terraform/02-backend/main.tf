# Создание бакета для Terraform state
# resource "yandex_iam_service_account_static_access_key" "sa_key" {
#   service_account_id = yandex_iam_service_account.terraform_sa.id
# }

resource "yandex_storage_bucket" "tf_state_bucket" {
  bucket = "tf-state-gorelovnn"
  #acl    = "private"

  anonymous_access_flags {
    read = false
    list = false
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}