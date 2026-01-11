# ###cloud vars
# # variable "token" {
# #   type        = string
# #   description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
# # }

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


# variable "default_zone" {
#   type        = string
#   default     = "ru-central1-a"
#   description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
# }

# variable "default_platform_id" {
#   type        = string
#   default     = "standard-v3"
#   description = "platform_id"
# }

# variable "default_cidr" {
#   type        = list(string)
#   default     = ["10.0.1.0/24"]
#   description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
# }

# variable "vpc_name" {
#   type        = string
#   default     = "develop"
#   description = "VPC network&subnet name"
# }

# # variable "image_id" {
# #   type        = string
# #   default     = "fd8u8ttgp0t4d19ov0k5" # Ubuntu-20.04-lts
# #   description = "default image id for VM"
# # }

# ### Web VM vars ###

# variable "web_instance_count" {
#   type        = number
#   default     = 2
#   description = "Number of web instances to create"
# }

# variable "web_instance_name_prefix" {
#   type        = string
#   default     = "web"
#   description = "Prefix for web instance names"
# }

# variable "web_instance_cpu" {
#   type        = number
#   default     = 2
#   description = "Number of CPU cores for web instances"
# }

# variable "web_instance_memory" {
#   type        = number
#   default     = 2
#   description = "Amount of memory for web instances (GB)"
# }

# variable "web_instance_username" {
#   type        = string
#   default     = "ubuntu"
#   description = "User for web instances"
# }

# ### Storage vars ###

# variable "storage_vm_name" {
#   type        = string
#   default     = "storage"
#   description = "default image id for VM"
# }

# variable "storage_vm_cpu_cores" {
#   type        = number
#   default     = 2
#   description = "Number of CPU cores for storage VM"
# }

# variable "storage_vm_memory_gb" {
#   type        = number
#   default     = 4
#   description = "Amount of memory for storage VM (GB)"
# }

# variable "storage_vm_boot_disk_size_gb" {
#   type        = number
#   default     = 10
#   description = "Boot disk size for storage VM (GB)"
# }

# variable "storage_instance_username" {
#   type        = string
#   default     = "ubuntu"
#   description = "User for storage instances"
# }

# ### Storage disks variables ###

# variable "storage_disks_count" {
#   type        = number
#   default     = 3
#   description = "Number of additional storage disks to create"
# }

# variable "storage_disk_name_prefix" {
#   type        = string
#   default     = "storage-disk"
#   description = "Prefix for storage disk names"
# }

# variable "storage_disk_type" {
#   type        = string
#   default     = "network-hdd"
#   description = "Type of storage disks"
# }

# variable "storage_disk_size_gb" {
#   type        = number
#   default     = 1
#   description = "Size of each storage disk (GB)"
# }

# variable "storage_disk_block_size" {
#   type        = number
#   default     = 4096
#   description = "Block size for storage disks"
# }

# ### Vars for_each-vm.tf ###

# variable "each_vm" {
#   type = list(object({
#     vm_name     = string
#     cpu         = number
#     ram         = number
#     disk_volume = number
#   }))
#   default = [
#     {
#       vm_name     = "main"
#       cpu         = 4
#       ram         = 4
#       disk_volume = 10
#     },
#     {
#       vm_name     = "replica"
#       cpu         = 2
#       ram         = 2
#       disk_volume = 5
#     }
#   ]
# }