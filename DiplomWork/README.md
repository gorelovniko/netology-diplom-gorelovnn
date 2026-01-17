# Дипломный практикум в Yandex.Cloud - `Горелов Николай`
22 декабря — 19 января FFOPS-30


* [Цели:](#цели)
* [Этапы выполнения:](#этапы-выполнения)
    * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
    * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
    * [Создание тестового приложения](#создание-тестового-приложения)
    * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
    * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
* [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
* [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

---

## <a name="Цели">Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---

## <a name="Создание облачной инфраструктуры">Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя



-2. Подготовьте [backend](https://developer.hashicorp.com/terraform/language/backend) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)

2. С помощью terraform был создан bucket в YandexCloud.

![](./img/01-backet.png)  

[== backend ==](./terraform/02-backend/main.tf)  

-3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.

3. Создание конфигурации Terraform происходит в созданном ранее бакете. Бекенд используется для хранения стейт файла.

Для этого в файле provider.tf дописываем необходимые параметры.

```bash

...
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
...

```


!!!!!!!!!!!!!!!!!!!!! Дописать что делал в консоле.
Также необходимо было добавить в переменные среды ключ доступа к бакету. Иначе файл просто не создастся из-за отсутствия прав.



![](./img/02-terraform.tfstate.png) 

4. Созданы VPC с подсетями в разных зонах доступности:

[main](./terraform/03-main-infrastructure/main.tf)

[locals](./terraform/03-main-infrastructure/locals.tf)

![vpc](./img/03-vpc.png)

5. Теперь можно развернуть инфраструктуру выполнив команду `terraform apply -auto-approve` без дополнительных ручных действий:


<details>
<summary>terraform apply</summary>  

```bash
nimda@vm1:03-main-infrastructure$ terraform apply -auto-approve
data.yandex_compute_image.cos: Reading...
data.yandex_compute_image.ubuntu_2204: Reading...
data.yandex_compute_image.cos: Read complete after 1s [id=fd8ern79qcejggqa6jpr]
data.yandex_compute_image.ubuntu_2204: Read complete after 1s [id=fd8armeucacj6ib7pkel]

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.public_ips_yaml will be created
  + resource "local_file" "public_ips_yaml" {
      + content              = (known after apply)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "../../ansible/infrastructure/inventory/group_vars/all/public_ips.yaml"
      + id                   = (known after apply)
    }

...

yandex_compute_instance.vm["node2"]: Creation complete after 40s [id=fv4181bit72l9q86r2ne]
yandex_compute_instance.vm["teamcity-server"]: Creation complete after 41s [id=fhm99v5q43pse4lhmq44]
yandex_compute_instance.vm["teamcity-agent"]: Creation complete after 41s [id=fhm0s9dprbrk52j09ioj]
yandex_compute_instance.vm["node1"]: Still creating... [50s elapsed]
yandex_compute_instance.vm["node1"]: Creation complete after 57s [id=epdc60livfp9eptopa43]
local_file.public_ips_yaml: Creating...
local_file.public_ips_yaml: Creation complete after 0s [id=0c669e2f42e31c2f9deab483e6c4cb244161ff24]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

current-workspace-name = "default"
k8s_net-id = "enphmli75ejj8pcio2sa"
vm_instances = {
  "cp1" = {
    "boot_disk_gb" = 30
    "cpu" = 4
    "fqdn" = "cp1.ru-central1.internal"
    "id" = "fhm17fe66rtp7jegk6s5"
    "internal_ip" = "10.10.10.1"
    "memory_gb" = 0.00390625
    "name" = "cp1"
    "nat_ip" = "158.160.104.163"
    "platform" = "standard-v3"
    "status" = "running"
    "zone" = "ru-central1-a"
  }
  "node1" = {
    "boot_disk_gb" = 30
    "cpu" = 4
    "fqdn" = "node1.ru-central1.internal"
    "id" = "epdc60livfp9eptopa43"
    "internal_ip" = "10.20.20.1"
    "memory_gb" = 0.00390625
    "name" = "node1"
    "nat_ip" = "158.160.82.203"
    "platform" = "standard-v3"
    "status" = "running"
    "zone" = "ru-central1-b"
  }
  "node2" = {
    "boot_disk_gb" = 30
    "cpu" = 4
    "fqdn" = "node2.ru-central1.internal"
    "id" = "fv4181bit72l9q86r2ne"
    "internal_ip" = "10.30.30.1"
    "memory_gb" = 0.00390625
    "name" = "node2"
    "nat_ip" = "158.160.198.85"
    "platform" = "standard-v3"
    "status" = "running"
    "zone" = "ru-central1-d"
  }
  "teamcity-agent" = {
    "boot_disk_gb" = 50
    "cpu" = 2
    "fqdn" = "teamcity-agent.ru-central1.internal"
    "id" = "fhm0s9dprbrk52j09ioj"
    "internal_ip" = "10.10.10.20"
    "memory_gb" = 0.001953125
    "name" = "teamcity-agent"
    "nat_ip" = "158.160.100.15"
    "platform" = "standard-v3"
    "status" = "running"
    "zone" = "ru-central1-a"
  }
  "teamcity-server" = {
    "boot_disk_gb" = 50
    "cpu" = 4
    "fqdn" = "teamcity-server.ru-central1.internal"
    "id" = "fhm99v5q43pse4lhmq44"
    "internal_ip" = "10.10.10.10"
    "memory_gb" = 0.0078125
    "name" = "teamcity-server"
    "nat_ip" = "158.160.117.236"
    "platform" = "standard-v3"
    "status" = "running"
    "zone" = "ru-central1-a"
  }
}
vpc-subnet-private1-id = "e9bn3l670mma589gs3fl"
vpc-subnet-private1-zone = "ru-central1-a"
vpc-subnet-private2-id = "e2lc609e18lt78polgh4"
vpc-subnet-private2-zone = "ru-central1-b"
vpc-subnet-private3-id = "fl8t1el8ftm2s6nvgulp"
vpc-subnet-private3-zone = "ru-central1-d"
```

</details>
<br>

Уничтожить всю инфраструктуру также можно одной командой используя `terraform destroy -auto-approve`:

<details>
<summary>terraform destroy</summary>

```bash
nimda@vm1:03-main-infrastructure$ terraform destroy -auto-approve
data.yandex_compute_image.cos: Reading...
data.yandex_compute_image.ubuntu_2204: Reading...
yandex_vpc_network.k8s_net: Refreshing state... [id=enphmli75ejj8pcio2sa]
data.yandex_compute_image.cos: Read complete after 0s [id=fd8ern79qcejggqa6jpr]
data.yandex_compute_image.ubuntu_2204: Read complete after 0s [id=fd8armeucacj6ib7pkel]
yandex_vpc_subnet.vpc-subnet-private3: Refreshing state... [id=fl8t1el8ftm2s6nvgulp]
yandex_vpc_subnet.vpc-subnet-private2: Refreshing state... [id=e2lc609e18lt78polgh4]
yandex_vpc_subnet.vpc-subnet-private1: Refreshing state... [id=e9bn3l670mma589gs3fl]
yandex_compute_instance.vm["node1"]: Refreshing state... [id=epdc60livfp9eptopa43]
yandex_compute_instance.vm["teamcity-agent"]: Refreshing state... [id=fhm0s9dprbrk52j09ioj]
yandex_compute_instance.vm["node2"]: Refreshing state... [id=fv4181bit72l9q86r2ne]
yandex_compute_instance.vm["teamcity-server"]: Refreshing state... [id=fhm99v5q43pse4lhmq44]
yandex_compute_instance.vm["cp1"]: Refreshing state... [id=fhm17fe66rtp7jegk6s5]
local_file.public_ips_yaml: Refreshing state... [id=0c669e2f42e31c2f9deab483e6c4cb244161ff24]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with
the following symbols:
  - destroy

Terraform will perform the following actions:

  # local_file.public_ips_yaml will be destroyed
  - resource "local_file" "public_ips_yaml" {
      - content              = <<-EOT
            ---
            public_ip:
              cp1:             158.160.104.163
              node1:           158.160.82.203
              node2:           158.160.198.85
              teamcity-server: 158.160.117.236
              teamcity-agent:  158.160.100.15
        EOT -> null
      - content_base64sha256 = "TtrzzWfePeyEb6Odf3NLSz/LijY44Hvs7cAByWW9PmI=" -> null
      - content_base64sha512 = "RlQi1na8drNkBzeciizxXDCOPvVrp/LgLQeK5i7hVEnBJkROhy6pyDTAmW6T6J2V0DMDjTG7sR9q9EGPQWjLgw==" -> null
      - content_md5          = "90a5ae3f40e33a637ee5c1e3f9e7ff0c" -> null
      - content_sha1         = "0c669e2f42e31c2f9deab483e6c4cb244161ff24" -> null
      - content_sha256       = "4edaf3cd67de3dec846fa39d7f734b4b3fcb8a3638e07becedc001c965bd3e62" -> null
      - content_sha512       = "465422d676bc76b36407379c8a2cf15c308e3ef56ba7f2e02d078ae62ee15449c126444e872ea9c834c0996e93e89d95d033038d31bbb11f6af4418f4168cb83" -> null

      ...

      - teamcity-server = {
          - boot_disk_gb = 50
          - cpu          = 4
          - fqdn         = "teamcity-server.ru-central1.internal"
          - id           = "fhm99v5q43pse4lhmq44"
          - internal_ip  = "10.10.10.10"
          - memory_gb    = 0.0078125
          - name         = "teamcity-server"
          - nat_ip       = "158.160.117.236"
          - platform     = "standard-v3"
          - status       = "running"
          - zone         = "ru-central1-a"
        }
    } -> null
  - vpc-subnet-private1-id   = "e9bn3l670mma589gs3fl" -> null
  - vpc-subnet-private1-zone = "ru-central1-a" -> null
  - vpc-subnet-private2-id   = "e2lc609e18lt78polgh4" -> null
  - vpc-subnet-private2-zone = "ru-central1-b" -> null
  - vpc-subnet-private3-id   = "fl8t1el8ftm2s6nvgulp" -> null
  - vpc-subnet-private3-zone = "ru-central1-d" -> null
local_file.public_ips_yaml: Destroying... [id=0c669e2f42e31c2f9deab483e6c4cb244161ff24]
local_file.public_ips_yaml: Destruction complete after 0s
yandex_compute_instance.vm["teamcity-agent"]: Destroying... [id=fhm0s9dprbrk52j09ioj]
yandex_compute_instance.vm["cp1"]: Destroying... [id=fhm17fe66rtp7jegk6s5]
yandex_compute_instance.vm["node1"]: Destroying... [id=epdc60livfp9eptopa43]
yandex_compute_instance.vm["node2"]: Destroying... [id=fv4181bit72l9q86r2ne]
yandex_compute_instance.vm["teamcity-server"]: Destroying... [id=fhm99v5q43pse4lhmq44]
yandex_compute_instance.vm["teamcity-agent"]: Still destroying... [id=fhm0s9dprbrk52j09ioj, 10s elapsed]
yandex_compute_instance.vm["node1"]: Still destroying... [id=epdc60livfp9eptopa43, 10s elapsed]
yandex_compute_instance.vm["cp1"]: Still destroying... [id=fhm17fe66rtp7jegk6s5, 10s elapsed]
yandex_compute_instance.vm["node2"]: Still destroying... [id=fv4181bit72l9q86r2ne, 10s elapsed]
yandex_compute_instance.vm["teamcity-server"]: Still destroying... [id=fhm99v5q43pse4lhmq44, 10s elapsed]
yandex_compute_instance.vm["teamcity-agent"]: Still destroying... [id=fhm0s9dprbrk52j09ioj, 20s elapsed]
yandex_compute_instance.vm["node1"]: Still destroying... [id=epdc60livfp9eptopa43, 20s elapsed]
yandex_compute_instance.vm["cp1"]: Still destroying... [id=fhm17fe66rtp7jegk6s5, 20s elapsed]
yandex_compute_instance.vm["teamcity-server"]: Still destroying... [id=fhm99v5q43pse4lhmq44, 20s elapsed]
yandex_compute_instance.vm["node2"]: Still destroying... [id=fv4181bit72l9q86r2ne, 20s elapsed]
yandex_compute_instance.vm["node2"]: Destruction complete after 24s
yandex_compute_instance.vm["teamcity-agent"]: Still destroying... [id=fhm0s9dprbrk52j09ioj, 30s elapsed]
yandex_compute_instance.vm["node1"]: Still destroying... [id=epdc60livfp9eptopa43, 30s elapsed]
yandex_compute_instance.vm["cp1"]: Still destroying... [id=fhm17fe66rtp7jegk6s5, 30s elapsed]
yandex_compute_instance.vm["teamcity-server"]: Still destroying... [id=fhm99v5q43pse4lhmq44, 30s elapsed]
yandex_compute_instance.vm["node1"]: Destruction complete after 31s
yandex_compute_instance.vm["cp1"]: Destruction complete after 32s
yandex_compute_instance.vm["teamcity-agent"]: Still destroying... [id=fhm0s9dprbrk52j09ioj, 40s elapsed]
yandex_compute_instance.vm["teamcity-server"]: Still destroying... [id=fhm99v5q43pse4lhmq44, 40s elapsed]
yandex_compute_instance.vm["teamcity-agent"]: Still destroying... [id=fhm0s9dprbrk52j09ioj, 50s elapsed]
yandex_compute_instance.vm["teamcity-server"]: Still destroying... [id=fhm99v5q43pse4lhmq44, 50s elapsed]
yandex_compute_instance.vm["teamcity-agent"]: Still destroying... [id=fhm0s9dprbrk52j09ioj, 1m0s elapsed]
yandex_compute_instance.vm["teamcity-server"]: Still destroying... [id=fhm99v5q43pse4lhmq44, 1m0s elapsed]
yandex_compute_instance.vm["teamcity-agent"]: Destruction complete after 1m2s
yandex_compute_instance.vm["teamcity-server"]: Destruction complete after 1m6s
yandex_vpc_subnet.vpc-subnet-private2: Destroying... [id=e2lc609e18lt78polgh4]
yandex_vpc_subnet.vpc-subnet-private1: Destroying... [id=e9bn3l670mma589gs3fl]
yandex_vpc_subnet.vpc-subnet-private3: Destroying... [id=fl8t1el8ftm2s6nvgulp]
yandex_vpc_subnet.vpc-subnet-private2: Destruction complete after 6s
yandex_vpc_subnet.vpc-subnet-private3: Destruction complete after 8s
yandex_vpc_subnet.vpc-subnet-private1: Destruction complete after 10s
yandex_vpc_network.k8s_net: Destroying... [id=enphmli75ejj8pcio2sa]
yandex_vpc_network.k8s_net: Destruction complete after 1s

Destroy complete! Resources: 10 destroyed.
```

</details>  

### Ожидаемые результаты достигнуты:

 - Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете.

---