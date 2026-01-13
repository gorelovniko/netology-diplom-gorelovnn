locals {
cores = {
    cp1         = 4
    node1       = 4
    node2       = 4
    gitlab-cicd = 4
  }

  memory = {
    cp1   = 4
    node1 = 4
    node2 = 4
    gitlab-cicd = 4
  }

  boot_disk_size = {
    cp1   = 20
    node1 = 20
    node2 = 20
    gitlab-cicd = 35
  }

  image_family = {
    cp1   = "ubuntu-2204-lts"
    node1 = "ubuntu-2204-lts"
    node2 = "ubuntu-2204-lts"
    gitlab-cicd = "ubuntu-2204-lts"
  }

  ipv4_zones = {
    cp1   = var.yandex-cloud-zone1
    node1 = var.yandex-cloud-zone2
    node2 = var.yandex-cloud-zone3
    gitlab-cicd   = var.yandex-cloud-zone1
  }

  ipv4_subnets = {
    cp1   = yandex_vpc_subnet.vpc-subnet-private1.id
    node1 = yandex_vpc_subnet.vpc-subnet-private2.id
    node2 = yandex_vpc_subnet.vpc-subnet-private3.id
    gitlab-cicd = yandex_vpc_subnet.vpc-subnet-private1.id
  }

  ipv4_internals = {
    cp1   = "10.10.10.1"
    node1 = "10.20.20.1"
    node2 = "10.30.30.1"
    gitlab-cicd = "10.10.10.10"
  }

  ipv4_nats = {
    cp1   = true
    node1 = true
    node2 = true
    gitlab-cicd = true
  }

  core_fraction = {
    cp1   = 20
    node1 = 20
    node2 = 20
    gitlab-cicd = 50
  }
}