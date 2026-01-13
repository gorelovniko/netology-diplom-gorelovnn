resource "local_file" "public_ips_yaml" {
  filename = "../../ansible/infrastructure/inventory/group_vars/all/public_ips.yaml"
  content = <<-EOT
---
public_ip:
  cp1:       ${yandex_compute_instance.vm["cp1"].network_interface[0].nat_ip_address}
  node1:     ${yandex_compute_instance.vm["node1"].network_interface[0].nat_ip_address}
  node2:     ${yandex_compute_instance.vm["node2"].network_interface[0].nat_ip_address}
  gitlab-cicd:     ${yandex_compute_instance.vm["gitlab-cicd"].network_interface[0].nat_ip_address}
EOT
  
  depends_on = [yandex_compute_instance.vm]

  #   # Запрещает удаление ресурса
  # lifecycle {
  #   prevent_destroy = true
  # }
  
}