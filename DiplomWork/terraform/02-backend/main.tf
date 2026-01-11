# Создание бакета для Terraform state
# resource "yandex_iam_service_account_static_access_key" "sa_key" {
#   service_account_id = yandex_iam_service_account.terraform_sa.id
# }

resource "yandex_storage_bucket" "tf_state_bucket" {
  bucket = "tf-state-gorelovnn"
  #acl    = "private"
}