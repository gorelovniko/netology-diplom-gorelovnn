output "current-workspace-name" {
  value = terraform.workspace
}

output "k8s_net-id" {
  value = yandex_vpc_network.k8s_net.id
}

output "vpc-subnet-private1-id" {
  value = yandex_vpc_subnet.vpc-subnet-private1.id
}

output "vpc-subnet-private2-id" {
  value = yandex_vpc_subnet.vpc-subnet-private2.id
}

output "vpc-subnet-private3-id" {
  value = yandex_vpc_subnet.vpc-subnet-private3.id
}

output "vpc-subnet-private1-zone" {
  value = yandex_vpc_subnet.vpc-subnet-private1.zone
}

output "vpc-subnet-private2-zone" {
  value = yandex_vpc_subnet.vpc-subnet-private2.zone
}

output "vpc-subnet-private3-zone" {
  value = yandex_vpc_subnet.vpc-subnet-private3.zone
}

# output "cp1" {
#   value = yandex_compute_instance.cp1.network_interface.0.nat_ip_address
# }

#  output "node1" {
#   value = yandex_compute_instance.node1.network_interface.0.nat_ip_address
# }

# output "node2" {
#   value = yandex_compute_instance.node2.network_interface.0.nat_ip_address
# }

# output "instance_ips" {
#   description = "Public IP addresses of all instances"
#   value = {
#     for key, instance in module.vm-for-each : 
#     key => instance.public_ip
#   }
# }

# output "cp1" {
#   value = module.vm-for-each["cp1"].public_ip  # or whatever output your module provides
# }

# output "node1" {
#   value = module.vm-for-each["node1"].public_ip
# }

# output "node2" {
#   value = module.vm-for-each["node2"].public_ip
# }


# # root outputs.tf
# output "all_public_ips" {
#   value = module.vm-for-each.public_ip
# }

# ####################################################
# # A unique identifier for this run.
# variable "TFC_RUN_ID" {
#   type    = string
#   default = ""
# }

# output "remote_execution_determine" {
#   value = "Run environment: %{if var.TFC_RUN_ID != ""}Remote%{else}Local%{endif}"
# }

# output "network-id" {
#   value = yandex_vpc_network.k8s_net.id
# }

output "vm_instances" {
  description = "Детальная информация о всех созданных виртуальных машинах"
  value = {
    for vm_name, vm in yandex_compute_instance.vm : vm_name => {
      id          = vm.id
      name        = vm.name
      zone        = vm.zone
      status      = vm.status
      fqdn        = vm.fqdn
      internal_ip = vm.network_interface[0].ip_address
      nat_ip      = vm.network_interface[0].nat_ip_address
      cpu         = vm.resources[0].cores
      memory_gb   = vm.resources[0].memory / 1024
      boot_disk_gb = vm.boot_disk[0].initialize_params[0].size
      platform    = vm.platform_id
    }
  }
}