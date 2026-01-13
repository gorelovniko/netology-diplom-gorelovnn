data "yandex_compute_image" "ubuntu_2204" {
  family = "ubuntu-2204-lts"
}

# Создаём ВМ напрямую
resource "yandex_compute_instance" "vm" {
  for_each = toset(["cp1", "node1", "node2","gitlab-cicd"])

  name        = each.key
  platform_id = "standard-v3"
  zone        = local.ipv4_zones[each.key]

  resources {
    cores         = local.cores[each.key]
    memory        = local.memory[each.key]
    core_fraction = local.core_fraction[each.key]
  }

  boot_disk {
    initialize_params {
      size = local.boot_disk_size[each.key]
      type = "network-hdd"
      image_id = data.yandex_compute_image.ubuntu_2204.id
    }
  }

  network_interface {
    subnet_id  = local.ipv4_subnets[each.key]
    ip_address = local.ipv4_internals[each.key]
    nat        = local.ipv4_nats[each.key]
  }


  scheduling_policy {preemptible = true}

  metadata = {
    user-data          = file("../cloud-init.yml")
  }
}
