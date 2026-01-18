locals {
cores = {
    cp1             = 4
    node1           = 4
    node2           = 4
    teamcity-server = 4
    teamcity-agent  = 2
  }

  memory = {
    cp1             = 4
    node1           = 4
    node2           = 4
    teamcity-server = 8
    teamcity-agent  = 2
  }

  boot_disk_size = {
    cp1             = 30
    node1           = 30
    node2           = 30
    teamcity-server = 50
    teamcity-agent  = 50
  }

  image_family = {
    cp1             = "ubuntu-2204-lts"
    node1           = "ubuntu-2204-lts"
    node2           = "ubuntu-2204-lts"
    teamcity-server = "container-optimized-image"
    teamcity-agent  = "container-optimized-image"
  }

  ipv4_zones = {
    cp1             = var.yandex-cloud-zone1
    node1           = var.yandex-cloud-zone2
    node2           = var.yandex-cloud-zone3
    teamcity-server = var.yandex-cloud-zone1
    teamcity-agent  = var.yandex-cloud-zone1
  }

  ipv4_subnets = {
    cp1             = yandex_vpc_subnet.vpc-subnet-private1.id
    node1           = yandex_vpc_subnet.vpc-subnet-private2.id
    node2           = yandex_vpc_subnet.vpc-subnet-private3.id
    teamcity-server = yandex_vpc_subnet.vpc-subnet-private1.id
    teamcity-agent  = yandex_vpc_subnet.vpc-subnet-private1.id
  }

  ipv4_internals = {
    cp1             = "10.10.10.1"
    node1           = "10.20.20.1"
    node2           = "10.30.30.1"
    teamcity-server = "10.10.10.10"
    teamcity-agent  = "10.10.10.20"
  }

  ipv4_nats = {
    cp1             = true
    node1           = true
    node2           = true
    teamcity-server = true
    teamcity-agent  = true
  }

  core_fraction = {
    cp1             = 20
    node1           = 20
    node2           = 20
    teamcity-server = 100
    teamcity-agent  = 20
  }

  
  app_nodeport   = 30003  # ваш NodePort для приложения
  grafana_nodeport = 30004  # NodePort для Grafana

}