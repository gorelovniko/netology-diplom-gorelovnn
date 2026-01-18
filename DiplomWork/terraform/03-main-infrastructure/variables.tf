### Cloud vars ###

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

# Yandex.Cloud zone.
variable "yc-zone" {
  default = "ru-central1"
}

# Zone 1.
variable "yandex-cloud-zone1" {
  default = "ru-central1-a"
}

# Zone 2.
variable "yandex-cloud-zone2" {
  default = "ru-central1-b"
}

# Zone 3.
variable "yandex-cloud-zone3" {
  default = "ru-central1-d"
}

# CIDR for private subnet 1.
variable "ipv4_cidr_private_subnet1" {
  default = "10.10.0.0/16"
}

# CIDR for private subnet 2.
variable "ipv4_cidr_private_subnet2" {
  default = "10.20.0.0/16"
}

# CIDR for private subnet 3.
variable "ipv4_cidr_private_subnet3" {
  default = "10.30.0.0/16"
}

variable "authorized_key" {
  default = ""
}

variable "cloud_config" {
  default = ""
}

