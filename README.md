# Дипломный практикум в Yandex.Cloud - `Горелов Николай`
22 декабря — 19 января FFOPS-30


* [Цели:](#цели)
* [Этапы выполнения:](#этапы-выполнения)
    * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
    * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
    * [Создание тестового приложения](#создание-тестового-приложения)
    * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
      * [Деплой инфраструктуры в terraform pipeline](#деплой-инфраструктуры-в-terraform-pipeline)
    * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
* [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
* [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

---

## <a name="Цели">Цели:</a>

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---

## <a name="Создание облачной инфраструктуры">Создание облачной инфраструктуры</a>

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создан сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами:

![](./DiplomWork/img/00-service%20account.png)

2. С помощью terraform был создан bucket в YandexCloud.

![](./DiplomWork/img//01-backet.png)  

[== backend ==](./terraform/02-backend/main.tf)  

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

![](./DiplomWork/img/02-terraform.tfstate.png) 

Также необходимо было добавить в переменные среды ключ доступа к бакету. Иначе файл просто не создастся из-за отсутствия прав.
Для этого нужно выполнить следующие команды в terminale:


```bash

$ yc iam access-key create --service-account-name terradiploma 
access_key:
  id: aje3jn02jscc23e3d4cc
  service_account_id: aje5cp35s6rqaruu12rc
  created_at: "2026-01-06T15:04:49.990741955Z"
  key_id: <Значение `key_id`>
secret: <Значение `Secret`> # значение secret будет доступно первый и последний раз


export AWS_ACCESS_KEY_ID=<Значение `key_id`>
export AWS_SECRET_ACCESS_KEY=<Значение `secret`>

```

Либо добавить команды export в ~/.bashrs, после перезагрузиться или выполнить без перезагрузки:

```bash

source ~/.bashrc

```


4. Созданы VPC с подсетями в разных зонах доступности:

[== main ==](./DiplomWork/terraform/03-main-infrastructure/main.tf)

[== locals ==](./DiplomWork/terraform/03-main-infrastructure/locals.tf)

![== vpc ==](./DiplomWork/img/03-vpc.png)

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

## <a name="Создание Kubernetes кластера">Создание Kubernetes кластера</a>

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Создадим кластер Kubernetes, используя [Ansible](https://www.ansible.com/)
и применяя [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/) развернём
его на созданных ранее трех виртуальных машинах Yandex.Cloud

Запустим наши виртуальные машины Yandex.Cloud, дождёмся готовности и назначения им внешних IP-адресов. После чего
автоматически создастся файл с адресами всех инстансев, которые будут использоваться в конфигурациях ansible:  

[== public_ips.yaml ==](./DiplomWork/ansible/infrastructure/inventory/group_vars/all/public_ips.yaml)

```yaml

---
public_ip:
  cp1:             178.154.220.138
  node1:           158.160.66.210
  node2:           158.160.167.127

```
Теперь перейдём в папку [конфигурации Ansible](./ansible/infrastructure) и инициализуем создание кластера:

<details>
<summary>infrastructure$ ansible-playbook -i inventory/hosts.yaml site.yaml</summary>

nimda@vm1:infrastructure$ ansible-playbook -i inventory/hosts.yaml site.yaml

PLAY [Setup Kubernetes Cluster] *******************************************************

TASK [Gathering Facts] ****************************************************************
ok: [localhost]

TASK [Set supplementary addresses in 'k8s-cluster.yml'] *******************************
changed: [localhost]

TASK [Set service CIDR in 'k8s-cluster.yml'] ******************************************
ok: [localhost]

TASK [Set pods CIDR in 'k8s-cluster.yml'] *********************************************
ok: [localhost]

TASK [Copy private key to directory 'tmp'] ********************************************
changed: [localhost]

PLAY [Setup common tools] *************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [node2]
ok: [node1]
ok: [cp1]

TASK [Install common tools] ***********************************************************
changed: [node1]
changed: [node2]
changed: [cp1]

PLAY [Setup Kubernetes Cluster] *******************************************************

TASK [Gathering Facts] ****************************************************************
ok: [cp1]

TASK [Install control plane-specific tools] *******************************************
changed: [cp1]

TASK [Install 'Calico' as binary] *****************************************************
[WARNING]: Module remote_tmp /root/.ansible/tmp did not exist and was created with a
mode of 0700, this may cause issues when running as another user. To avoid this,
create the remote_tmp dir with the correct permissions manually
changed: [cp1]

TASK [Clone 'Kubespray' from git-repository] ******************************************
changed: [cp1]

TASK [Install required tools for 'Kubespray'] *****************************************
changed: [cp1]

TASK [Copy example inventory] *********************************************************
changed: [cp1]

TASK [Upload content of 'k8s-cluster' directory to host] ******************************
changed: [cp1]

TASK [Upload 'hosts.yml' to host] *****************************************************
changed: [cp1]

TASK [Upload private key to host (to allow 'Kubespray' establish ssh-connections to nodes)] ***
changed: [cp1]

PLAY [Setup Kubernetes Cluster] *******************************************************

TASK [Gathering Facts] ****************************************************************
ok: [cp1]

TASK [Applying 'Kubespray' to create Kubernetes cluster] ******************************
changed: [cp1]

PLAY [Setup Kubernetes Cluster] *******************************************************

TASK [Gathering Facts] ****************************************************************
ok: [cp1]

TASK [Create remote directory if it does not exist] ***********************************
changed: [cp1]

TASK [Copy file with owner and permissions (file 'admin.conf' created after 'kubeadm init'!)] ***
changed: [cp1]

TASK [Rename file 'admin.conf' to 'config'] *******************************************
changed: [cp1]

PLAY [Grant permissions on cluster to non-sudo localhost user] ************************

TASK [Gathering Facts] ****************************************************************
ok: [localhost]

TASK [Create local directory] *********************************************************
ok: [localhost]

PLAY [Grant localhost access to cluster] **********************************************

TASK [Gathering Facts] ****************************************************************
ok: [cp1]

TASK [Download file './kube/config' from cluster to localhost directory] **************
changed: [cp1]

PLAY [Grant localhost access to cluster] **********************************************

TASK [Gathering Facts] ****************************************************************
ok: [localhost]

TASK [Replace private IP-address with public one] *************************************
changed: [localhost]

TASK [Get available nodes] ************************************************************
changed: [localhost]

TASK [Available nodes] ****************************************************************
ok: [localhost] => {
    "msg": [
        "NAME    STATUS   ROLES           AGE    VERSION",
        "cp1     Ready    control-plane   2m4s   v1.34.3",
        "node1   Ready    <none>          87s    v1.34.3",
        "node2   Ready    <none>          87s    v1.34.3"
    ]
}

PLAY [Setup Kubernetes Cluster] *******************************************************

TASK [Gathering Facts] ****************************************************************
ok: [localhost]

TASK [Clean up temporary files] *******************************************************
changed: [localhost]

PLAY [Setup Kubernetes Dashboard] *****************************************************

TASK [Gathering Facts] ****************************************************************
ok: [cp1]

TASK [Upload manifest for Kubernetes Dashboard] ***************************************
changed: [cp1]

TASK [Apply manifest for Kubernetes Dashboard] ****************************************
changed: [cp1]

TASK [Upload manifest for service account] ********************************************
changed: [cp1]

TASK [Apply manifest for service account] *********************************************
changed: [cp1]

TASK [Upload manifest for RBAC] *******************************************************
changed: [cp1]

TASK [Apply manifest for RBAC] ********************************************************
changed: [cp1]

TASK [Generate access token: kubectl -n kubernetes-dashboard create token admin-user] ***
changed: [cp1]

TASK [Access token is] ****************************************************************
ok: [cp1] => {
    "msg": [
        "eyJhbGciOiJSUzI1NiIsImtpZCI6IjVyN1phWlRKb20xNklSTXk1MWJTN050NEZJbWpENklPbTl1Z1ZvR1llb00ifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzY4NjM2MDQ0LCJpYXQiOjE3Njg2MzI0NDQsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiMDcyYTg4MzgtYzI4Yi00YjBiLTg5YTAtNzVjNzkzM2VkNjRhIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiMmQ5NDFkY2YtN2NmYi00Y2M1LThiNmYtNmQyOWVkNmRlMTZmIn19LCJuYmYiOjE3Njg2MzI0NDQsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbi11c2VyIn0.YWgK0RKDgW36CmJABfElc3Xfwtv-HjHZ9eHIvHu9yU_r59dX6JtIM3aSoF8FW5Fpm4Y8V3Bghrx7xpeK670HnhCAYoMeTyTx5WqJ-yGcmXrraW65zW5wQg28Goko-YR2tAdO4oRLUjOp9lWtk8BTQ2-wMznfMc_AF_MlJnTMOuPQVctX9u4Igs0Ubb4n1RcR1XQR69krDvz4KU6HtVW8pzsRZiC82tiIoQcHJ4vQk-w1LypzWX85JYJb4-Wp2g3J0Qpub-_PrQ0uA1Sp9mStEdRV-amtLgSTZSSBRpOSJpzWTOYu-HCq_HedL701jy3abIJID8J7E8uhxCK21w-oPQ",
        "1. Run 'kubectl proxy' on host supposed to be used for access to Kubernetes Dashboard",
        "2. Proceed to the link: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/",
        "3. Select 'Token' option and enter the token."
    ]
}

PLAY [Deploy TeamCity Server] *********************************************************

TASK [Gathering Facts] ****************************************************************
ok: [teamcity-server]

TASK [Install TeamCity server] ********************************************************
changed: [teamcity-server]

PLAY [Deploy TeamCity Agent] **********************************************************

TASK [Gathering Facts] ****************************************************************
ok: [teamcity-agent]

TASK [Create Teamcity Agent folder] ***************************************************
changed: [teamcity-agent]

TASK [Install TeamCity Agent from Docker image] ***************************************
changed: [teamcity-agent]

PLAY [Postgres installation] **********************************************************

TASK [Gathering Facts] ****************************************************************
ok: [teamcity-server]

TASK [Update apt repo and cache] ******************************************************
changed: [teamcity-server]

TASK [Upgrade all packages on servers] ************************************************
changed: [teamcity-server]

TASK [Install required packages] ******************************************************
changed: [teamcity-server]

TASK [Set up PostgreSQL 14 repo] ******************************************************
changed: [teamcity-server]

TASK [Install PostgreSQL] *************************************************************
changed: [teamcity-server]

TASK [Ensure PostgreSQL is listening] *************************************************
changed: [teamcity-server]

TASK [Add new configuration to "pg_hba.conf"] *****************************************
changed: [teamcity-server]

TASK [Change peer identification to trust] ********************************************
changed: [teamcity-server]

TASK [Create a Superuser PostgreSQL database user] ************************************
[WARNING]: Module remote_tmp /var/lib/postgresql/.ansible/tmp did not exist and was
created with a mode of 0700, this may cause issues when running as another user. To
avoid this, create the remote_tmp dir with the correct permissions manually
changed: [teamcity-server]

RUNNING HANDLER [Restart_Postgresql] **************************************************
changed: [teamcity-server]

RUNNING HANDLER [Enable_Postgresql] ***************************************************
ok: [teamcity-server]

PLAY RECAP ****************************************************************************
cp1                        : ok=28   changed=21   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
localhost                  : ok=13   changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node1                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node2                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
teamcity-agent             : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
teamcity-server            : ok=14   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

</details>
<br>

После инициализации кластера конфигурация доступа к нему хранится в домашней папке пользователя по пути `~/.kube/config`:

![](./DiplomWork/img/04-kube-config.png)

Доступ к кластеру можно проверить, получив, например, набор подов командой `kubectl get pods`:

![](./DiplomWork/img/05-kube-get-pods.png)

На данный момент полная инфраструктура нашего Kubernetes-кластера выглядит следующим образом:

<details>
<summary>Полная инфраструктур сейчас</summary>

```bash

nimda@vm1:03-main-infrastructure$ kubectl get all,cm,sts,svc,deploy,sa,rs,po,pv,pvc,ep -A -o wide 
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAMESPACE              NAME                                             READY   STATUS    RESTARTS      AGE   IP               NODE    NOMINATED NODE   READINESS GATES
kube-system            pod/calico-kube-controllers-85d77456b8-wsb6v     1/1     Running   0             36m   10.200.104.1     node2   <none>           <none>
kube-system            pod/calico-node-6qgtf                            1/1     Running   0             36m   10.20.20.1       node1   <none>           <none>
kube-system            pod/calico-node-7wbt7                            1/1     Running   0             36m   10.30.30.1       node2   <none>           <none>
kube-system            pod/calico-node-sgxkf                            1/1     Running   0             36m   10.10.10.1       cp1     <none>           <none>
kube-system            pod/coredns-64b5cc5cbc-d28hh                     1/1     Running   0             36m   10.200.166.129   node1   <none>           <none>
kube-system            pod/coredns-64b5cc5cbc-vnd8j                     1/1     Running   0             36m   10.200.104.3     node2   <none>           <none>
kube-system            pod/dns-autoscaler-5594cbb9c4-bqklw              1/1     Running   0             36m   10.200.104.2     node2   <none>           <none>
kube-system            pod/kube-apiserver-cp1                           1/1     Running   1             37m   10.10.10.1       cp1     <none>           <none>
kube-system            pod/kube-controller-manager-cp1                  1/1     Running   3 (35m ago)   37m   10.10.10.1       cp1     <none>           <none>
kube-system            pod/kube-proxy-2jgc5                             1/1     Running   0             36m   10.20.20.1       node1   <none>           <none>
kube-system            pod/kube-proxy-wcl77                             1/1     Running   0             36m   10.30.30.1       node2   <none>           <none>
kube-system            pod/kube-proxy-wf6nd                             1/1     Running   0             36m   10.10.10.1       cp1     <none>           <none>
kube-system            pod/kube-scheduler-cp1                           1/1     Running   1             37m   10.10.10.1       cp1     <none>           <none>
kube-system            pod/nginx-proxy-node1                            1/1     Running   0             36m   10.20.20.1       node1   <none>           <none>
kube-system            pod/nginx-proxy-node2                            1/1     Running   0             36m   10.30.30.1       node2   <none>           <none>
kube-system            pod/nodelocaldns-7c2t7                           1/1     Running   0             36m   10.20.20.1       node1   <none>           <none>
kube-system            pod/nodelocaldns-7tqdc                           1/1     Running   0             36m   10.10.10.1       cp1     <none>           <none>
kube-system            pod/nodelocaldns-mkwvs                           1/1     Running   0             36m   10.30.30.1       node2   <none>           <none>
kubernetes-dashboard   pod/dashboard-metrics-scraper-5ffb7d645f-8lcpq   1/1     Running   0             35m   10.200.166.130   node1   <none>           <none>
kubernetes-dashboard   pod/kubernetes-dashboard-57f54bb69-cjqxj         1/1     Running   0             35m   10.200.104.4     node2   <none>           <none>

NAMESPACE              NAME                                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
default                service/kubernetes                  ClusterIP   10.32.0.1      <none>        443/TCP                  37m   <none>
kube-system            service/coredns                     ClusterIP   10.32.0.3      <none>        53/UDP,53/TCP,9153/TCP   36m   k8s-app=kube-dns
kubernetes-dashboard   service/dashboard-metrics-scraper   ClusterIP   10.32.216.39   <none>        8000/TCP                 35m   k8s-app=dashboard-metrics-scraper
kubernetes-dashboard   service/kubernetes-dashboard        ClusterIP   10.32.25.204   <none>        443/TCP                  35m   k8s-app=kubernetes-dashboard

NAMESPACE     NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE   CONTAINERS    IMAGES                                          SELECTOR
kube-system   daemonset.apps/calico-node    3         3         3       3            3           kubernetes.io/os=linux   36m   calico-node   quay.io/calico/node:v3.30.5                     k8s-app=calico-node
kube-system   daemonset.apps/kube-proxy     3         3         3       3            3           kubernetes.io/os=linux   37m   kube-proxy    registry.k8s.io/kube-proxy:v1.34.3              k8s-app=kube-proxy
kube-system   daemonset.apps/nodelocaldns   3         3         3       3            3           kubernetes.io/os=linux   36m   node-cache    registry.k8s.io/dns/k8s-dns-node-cache:1.25.0   k8s-app=node-local-dns

NAMESPACE              NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                  IMAGES                                                       SELECTOR
kube-system            deployment.apps/calico-kube-controllers     1/1     1            1           36m   calico-kube-controllers     quay.io/calico/kube-controllers:v3.30.5                      k8s-app=calico-kube-controllers
kube-system            deployment.apps/coredns                     2/2     2            2           36m   coredns                     registry.k8s.io/coredns/coredns:v1.12.1                      k8s-app=kube-dns
kube-system            deployment.apps/dns-autoscaler              1/1     1            1           36m   autoscaler                  registry.k8s.io/cpa/cluster-proportional-autoscaler:v1.8.8   k8s-app=dns-autoscaler
kubernetes-dashboard   deployment.apps/dashboard-metrics-scraper   1/1     1            1           35m   dashboard-metrics-scraper   kubernetesui/metrics-scraper:v1.0.8                          k8s-app=dashboard-metrics-scraper
kubernetes-dashboard   deployment.apps/kubernetes-dashboard        1/1     1            1           35m   kubernetes-dashboard        kubernetesui/dashboard:v2.6.1                                k8s-app=kubernetes-dashboard

NAMESPACE              NAME                                                   DESIRED   CURRENT   READY   AGE   CONTAINERS                  IMAGES                                                       SELECTOR
kube-system            replicaset.apps/calico-kube-controllers-85d77456b8     1         1         1       36m   calico-kube-controllers     quay.io/calico/kube-controllers:v3.30.5                      k8s-app=calico-kube-controllers,pod-template-hash=85d77456b8
kube-system            replicaset.apps/coredns-64b5cc5cbc                     2         2         2       36m   coredns                     registry.k8s.io/coredns/coredns:v1.12.1                      k8s-app=kube-dns,pod-template-hash=64b5cc5cbc
kube-system            replicaset.apps/dns-autoscaler-5594cbb9c4              1         1         1       36m   autoscaler                  registry.k8s.io/cpa/cluster-proportional-autoscaler:v1.8.8   k8s-app=dns-autoscaler,pod-template-hash=5594cbb9c4
kubernetes-dashboard   replicaset.apps/dashboard-metrics-scraper-5ffb7d645f   1         1         1       35m   dashboard-metrics-scraper   kubernetesui/metrics-scraper:v1.0.8                          k8s-app=dashboard-metrics-scraper,pod-template-hash=5ffb7d645f
kubernetes-dashboard   replicaset.apps/kubernetes-dashboard-57f54bb69         1         1         1       35m   kubernetes-dashboard        kubernetesui/dashboard:v2.6.1                                k8s-app=kubernetes-dashboard,pod-template-hash=57f54bb69

NAMESPACE              NAME                                                             DATA   AGE
default                configmap/kube-root-ca.crt                                       1      37m
kube-node-lease        configmap/kube-root-ca.crt                                       1      37m
kube-public            configmap/cluster-info                                           5      37m
kube-public            configmap/kube-root-ca.crt                                       1      37m
kube-system            configmap/calico-config                                          3      36m
kube-system            configmap/coredns                                                1      36m
kube-system            configmap/dns-autoscaler                                         1      36m
kube-system            configmap/extension-apiserver-authentication                     6      37m
kube-system            configmap/kube-apiserver-legacy-service-account-token-tracking   1      37m
kube-system            configmap/kube-proxy                                             2      37m
kube-system            configmap/kube-root-ca.crt                                       1      37m
kube-system            configmap/kubeadm-config                                         1      37m
kube-system            configmap/kubelet-config                                         1      37m
kube-system            configmap/kubernetes-services-endpoint                           2      36m
kube-system            configmap/nodelocaldns                                           1      36m
kubernetes-dashboard   configmap/kube-root-ca.crt                                       1      35m
kubernetes-dashboard   configmap/kubernetes-dashboard-settings                          0      35m

NAMESPACE              NAME                                                         SECRETS   AGE
default                serviceaccount/default                                       0         37m
kube-node-lease        serviceaccount/default                                       0         37m
kube-public            serviceaccount/default                                       0         37m
kube-system            serviceaccount/attachdetach-controller                       0         37m
kube-system            serviceaccount/bootstrap-signer                              0         37m
kube-system            serviceaccount/calico-cni-plugin                             0         36m
kube-system            serviceaccount/calico-kube-controllers                       0         36m
kube-system            serviceaccount/calico-node                                   0         36m
kube-system            serviceaccount/certificate-controller                        0         37m
kube-system            serviceaccount/clusterrole-aggregation-controller            0         37m
kube-system            serviceaccount/coredns                                       0         36m
kube-system            serviceaccount/cronjob-controller                            0         37m
kube-system            serviceaccount/daemon-set-controller                         0         37m
kube-system            serviceaccount/default                                       0         37m
kube-system            serviceaccount/deployment-controller                         0         37m
kube-system            serviceaccount/disruption-controller                         0         37m
kube-system            serviceaccount/dns-autoscaler                                0         36m
kube-system            serviceaccount/endpoint-controller                           0         37m
kube-system            serviceaccount/endpointslice-controller                      0         37m
kube-system            serviceaccount/endpointslicemirroring-controller             0         37m
kube-system            serviceaccount/ephemeral-volume-controller                   0         37m
kube-system            serviceaccount/expand-controller                             0         37m
kube-system            serviceaccount/generic-garbage-collector                     0         37m
kube-system            serviceaccount/horizontal-pod-autoscaler                     0         37m
kube-system            serviceaccount/job-controller                                0         37m
kube-system            serviceaccount/kube-proxy                                    0         37m
kube-system            serviceaccount/legacy-service-account-token-cleaner          0         37m
kube-system            serviceaccount/namespace-controller                          0         37m
kube-system            serviceaccount/node-controller                               0         37m
kube-system            serviceaccount/nodelocaldns                                  0         36m
kube-system            serviceaccount/persistent-volume-binder                      0         37m
kube-system            serviceaccount/pod-garbage-collector                         0         37m
kube-system            serviceaccount/pv-protection-controller                      0         37m
kube-system            serviceaccount/pvc-protection-controller                     0         37m
kube-system            serviceaccount/replicaset-controller                         0         37m
kube-system            serviceaccount/replication-controller                        0         37m
kube-system            serviceaccount/resource-claim-controller                     0         37m
kube-system            serviceaccount/resourcequota-controller                      0         37m
kube-system            serviceaccount/root-ca-cert-publisher                        0         37m
kube-system            serviceaccount/service-account-controller                    0         37m
kube-system            serviceaccount/service-cidrs-controller                      0         37m
kube-system            serviceaccount/statefulset-controller                        0         37m
kube-system            serviceaccount/token-cleaner                                 0         37m
kube-system            serviceaccount/ttl-after-finished-controller                 0         37m
kube-system            serviceaccount/ttl-controller                                0         37m
kube-system            serviceaccount/validatingadmissionpolicy-status-controller   0         37m
kube-system            serviceaccount/volumeattributesclass-protection-controller   0         37m
kubernetes-dashboard   serviceaccount/admin-user                                    0         35m
kubernetes-dashboard   serviceaccount/default                                       0         35m
kubernetes-dashboard   serviceaccount/kubernetes-dashboard                          0         35m

NAMESPACE              NAME                                  ENDPOINTS                                                       AGE
default                endpoints/kubernetes                  10.10.10.1:6443                                                 37m
kube-system            endpoints/coredns                     10.200.104.3:53,10.200.166.129:53,10.200.104.3:53 + 3 more...   36m
kubernetes-dashboard   endpoints/dashboard-metrics-scraper   10.200.166.130:8000                                             35m
kubernetes-dashboard   endpoints/kubernetes-dashboard        10.200.104.4:8443                                               35m

```

</details>
<br>

Как результат, на трех виртуальных машинах Yandex.Cloud мы развернули работоспособный кластер Kubernetes и получили
конфигурацию доступа к нему в локальной папке `~/.kube`. Благодаря этому мы имеем возможность выполнения
команд `kubectl` из локального окружения.


### Ожидаемые результаты достигнуты:

- Работоспособный Kubernetes кластер.
- В файле `~/.kube/config` находятся данные для доступа к кластеру.
- Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.
  
  ![](./DiplomWork/img/06-kube-get-pods-allnamespaces.png)

---

## <a name="Создание тестового приложения">Создание тестового приложения</a>

Подготовим простейшее [тестовое веб-приложение](./DiplomWork/diploma-webapp/web-app/), состоящее из
единственной [html-страницы](./DiplomWork/diploma-webapp/web-app/index.html), отображающей некоторые сведения:

````html

<html>
<head>
    <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
    <title>Netology DEVOPS</title>
    <link rel="icon" type="image/x-icon" href="favicon.png">
 </head>
<body>
<img src="diploma-img.jpeg" alt="Дипломная работа" class="diploma-image">
<h1>Diploma work Netology DEVOPS</h1>
<h2>Gorelov-NN</h2>
<h3>v.0.0.1</h3>
</body>
</html>

````

Также подготовим простую [конфигурацию веб-сервера](./DiplomWork/diploma-webapp/nginx/nginx.conf), позволяющую выводить статические
данные (в нашем случае - страницу [index.html](./DiplomWork/diploma-webapp/web-app/index.html)):

````nginx configuration

server {
    listen 80;
    server_name  testref.com www.testref.com; # Name of virtual server (delivered in "HOST" header).

    access_log  /var/log/nginx/domains/testref.com-access.log  main; # Access logging.
    error_log   /var/log/nginx/domains/testref.com-error.log info;   # Error logging.

    location / { # Handles a certain type of client request.
        root /; #  Directory that will be used to search for a file
        index index.html;  # Defines files that will be used as an index.
        try_files $uri /index.html; # Checks whether the specified file or directory exists.
    }
}

````

Контейнеризируем данное веб-приложение с помощью Docker используя образ веб-сервера [Nginx](https://hub.docker.com/_/nginx/):

````Dockerfile

FROM nginx
COPY web-app/index.html /usr/share/nginx/html
COPY web-app/diploma-img.jpeg /usr/share/nginx/html/
COPY web-app/favicon.png /usr/share/nginx/html/
ADD nginx/nginx.conf /nginx/nginx.conf

````

В целях проверки работоспособности соберем образ:

Перейдём в папку содержащюю Dockerfile и запустим сборку: 

![](./DiplomWork/img/07-docker%20build.png)


Образ собран и присутствует в репозитории под тегом `nikogorelov/gnn-diploma-netology:0.0.1`:

![](./DiplomWork/img/07-docker%20ls.png)

Запустим собранный образ локально:

![](./DiplomWork/img/08-docker-run-local.png)

Видим, что контейнеризированное веб-приложение доступно по `localhost` на стандартном порту `80`:

![](./DiplomWork/img/09-local-web-app-docker.png)


Для хранения разворачиваемого веб-приложения создадим на [github.com](https://github.com) отдельный репозиторий
с именем ["diploma-webapp"](https://github.com/gorelovniko/diploma-webapp):

![](./DiplomWork/img/10-github-repo-webapp.png)

Для хранения же Docker-образа воспользуемся репозиторием [dockerhub.com](https://hub.docker.com/). Для этого
сначала залогинимся в него (учётная запись у нас уже имеется):

![](./DiplomWork/img/11-docker-login.png)

И после успешной аутентификации отправим наш образ в репозиторий:

![](./DiplomWork/img/12-docker-push.png)

После этого наш образ можно
[наблюдать в репозитории](https://hub.docker.com/repository/docker/nikogorelov/gnn-diploma-netology/general) через веб-интерфейс:

![](./DiplomWork/img/13-docker-repo.png)


### Ожидаемый результат достигнут:

- Git репозиторий с тестовым приложением и Dockerfile.

  [Git репозиторий](https://github.com/gorelovniko/diploma-webapp)  
  [Dockerfile](https://github.com/gorelovniko/diploma-webapp/blob/main/Dockerfile)  

- Регистри с собранным docker image. В качестве регистри выбран DockerHub

[Docker image](https://hub.docker.com/repository/docker/nikogorelov/gnn-diploma-netology/general)

---

## <a name="Подготовка cистемы мониторинга и деплой приложения">Подготовка cистемы мониторинга и деплой приложения</a>

Создадим систему мониторинга с помощью пакета [Kube-Prometheus](https://github.com/prometheus-operator/kube-prometheus).

Этот пакет содержит в себе полный набор инструментов, позволяющих реализовать мониторинг кластера и приложений, работающих в нём.

Итак развернём его в нашем кластере.

Клонируем [Kube-Prometheus](https://github.com/prometheus-operator/kube-prometheus) в папку с проектом, перейдём в неё и выполним следующее:

```bash

cd ./netology-diplom-gorelovnn/DiplomWork/kube-prometheus/

# Создадим отдельный namespace
kubectl create namespace monitoring

# Применяем CRDs и настройки
kubectl apply --server-side -f manifests/setup/

```
![](./DiplomWork/img/14-kube-prometheus-deploy.png)


```bash

kubectl wait \
  --for condition=Established \
  --all CustomResourceDefinition \
  --namespace=monitoring

```
![](./DiplomWork/img/15-kube-prometheus-deploy1.png)

```bash

kubectl apply -f manifests/

```

<details>
<summary>kubectl apply -f manifests/</summary>

nimda@vm1:kube-prometheus$ kubectl apply -f manifests/
alertmanager.monitoring.coreos.com/main created
networkpolicy.networking.k8s.io/alertmanager-main created
poddisruptionbudget.policy/alertmanager-main created
prometheusrule.monitoring.coreos.com/alertmanager-main-rules created
secret/alertmanager-main created
service/alertmanager-main created
serviceaccount/alertmanager-main created
servicemonitor.monitoring.coreos.com/alertmanager-main created
clusterrole.rbac.authorization.k8s.io/blackbox-exporter created
clusterrolebinding.rbac.authorization.k8s.io/blackbox-exporter created
configmap/blackbox-exporter-configuration created
deployment.apps/blackbox-exporter created
networkpolicy.networking.k8s.io/blackbox-exporter created
service/blackbox-exporter created
serviceaccount/blackbox-exporter created
servicemonitor.monitoring.coreos.com/blackbox-exporter created
secret/grafana-config created
secret/grafana-datasources created
configmap/grafana-dashboard-alertmanager-overview created
configmap/grafana-dashboard-apiserver created
configmap/grafana-dashboard-cluster-total created
configmap/grafana-dashboard-controller-manager created
configmap/grafana-dashboard-grafana-overview created
configmap/grafana-dashboard-k8s-resources-cluster created
configmap/grafana-dashboard-k8s-resources-multicluster created
configmap/grafana-dashboard-k8s-resources-namespace created
configmap/grafana-dashboard-k8s-resources-node created
configmap/grafana-dashboard-k8s-resources-pod created
configmap/grafana-dashboard-k8s-resources-windows-cluster created
configmap/grafana-dashboard-k8s-resources-windows-namespace created
configmap/grafana-dashboard-k8s-resources-windows-pod created
configmap/grafana-dashboard-k8s-resources-workload created
configmap/grafana-dashboard-k8s-resources-workloads-namespace created
configmap/grafana-dashboard-k8s-windows-cluster-rsrc-use created
configmap/grafana-dashboard-k8s-windows-node-rsrc-use created
configmap/grafana-dashboard-kubelet created
configmap/grafana-dashboard-namespace-by-pod created
configmap/grafana-dashboard-namespace-by-workload created
configmap/grafana-dashboard-node-cluster-rsrc-use created
configmap/grafana-dashboard-node-rsrc-use created
configmap/grafana-dashboard-nodes-aix created
configmap/grafana-dashboard-nodes-darwin created
configmap/grafana-dashboard-nodes created
configmap/grafana-dashboard-persistentvolumesusage created
configmap/grafana-dashboard-pod-total created
configmap/grafana-dashboard-prometheus-remote-write created
configmap/grafana-dashboard-prometheus created
configmap/grafana-dashboard-proxy created
configmap/grafana-dashboard-scheduler created
configmap/grafana-dashboard-workload-total created
configmap/grafana-dashboards created
deployment.apps/grafana created
networkpolicy.networking.k8s.io/grafana created
prometheusrule.monitoring.coreos.com/grafana-rules created
service/grafana created
serviceaccount/grafana created
servicemonitor.monitoring.coreos.com/grafana created
prometheusrule.monitoring.coreos.com/kube-prometheus-rules created
clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
deployment.apps/kube-state-metrics created
networkpolicy.networking.k8s.io/kube-state-metrics created
prometheusrule.monitoring.coreos.com/kube-state-metrics-rules created
service/kube-state-metrics created
serviceaccount/kube-state-metrics created
servicemonitor.monitoring.coreos.com/kube-state-metrics created
prometheusrule.monitoring.coreos.com/kubernetes-monitoring-rules created
servicemonitor.monitoring.coreos.com/kube-apiserver created
servicemonitor.monitoring.coreos.com/coredns created
servicemonitor.monitoring.coreos.com/kube-controller-manager created
servicemonitor.monitoring.coreos.com/kube-scheduler created
servicemonitor.monitoring.coreos.com/kubelet created
clusterrole.rbac.authorization.k8s.io/node-exporter created
clusterrolebinding.rbac.authorization.k8s.io/node-exporter created
daemonset.apps/node-exporter created
networkpolicy.networking.k8s.io/node-exporter created
prometheusrule.monitoring.coreos.com/node-exporter-rules created
service/node-exporter created
serviceaccount/node-exporter created
servicemonitor.monitoring.coreos.com/node-exporter created
clusterrole.rbac.authorization.k8s.io/prometheus-k8s created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-k8s created
networkpolicy.networking.k8s.io/prometheus-k8s created
poddisruptionbudget.policy/prometheus-k8s created
prometheus.monitoring.coreos.com/k8s created
prometheusrule.monitoring.coreos.com/prometheus-k8s-prometheus-rules created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s-config created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s-config created
role.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s created
service/prometheus-k8s created
serviceaccount/prometheus-k8s created
servicemonitor.monitoring.coreos.com/prometheus-k8s created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
clusterrole.rbac.authorization.k8s.io/prometheus-adapter created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-adapter created
clusterrolebinding.rbac.authorization.k8s.io/resource-metrics:system:auth-delegator created
clusterrole.rbac.authorization.k8s.io/resource-metrics-server-resources created
configmap/adapter-config created
deployment.apps/prometheus-adapter created
networkpolicy.networking.k8s.io/prometheus-adapter created
poddisruptionbudget.policy/prometheus-adapter created
rolebinding.rbac.authorization.k8s.io/resource-metrics-auth-reader created
service/prometheus-adapter created
serviceaccount/prometheus-adapter created
servicemonitor.monitoring.coreos.com/prometheus-adapter created
clusterrole.rbac.authorization.k8s.io/prometheus-operator created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
deployment.apps/prometheus-operator created
networkpolicy.networking.k8s.io/prometheus-operator created
prometheusrule.monitoring.coreos.com/prometheus-operator-rules created
service/prometheus-operator created
serviceaccount/prometheus-operator created
servicemonitor.monitoring.coreos.com/prometheus-operator created

</details>
<br>

Доступ к развернутым в кластере приложениям мониторинга можно организовать несколькими способами, например:
- создать сервис вида NodePort, и получать доступ по внешним IP-адресам любой из нод кластера
в диапазоне портов от 30000 до 32768;
- создать сервис вида LoadBalancer и получать доступ по единому IP-адресу балансировщика через любой желаемый порт;
- организовать сетевой балансировщик нагрузки на уровне облачного провайдера;
- воспользоваться проброской портов и получить доступ к сервисам мониторинга из локального окружения.

Воспользуемся последним из перечисленных способов по причине его простоты.

Когда все ресурсы запустились, можно выполнить проброску портов кластера в локальное окружение с помощью команды
`kubectl port-forward`:

````bash
$ kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
Handling connection for 9090
...
$ kubectl --namespace monitoring port-forward svc/grafana 3000
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
Handling connection for 3000
...
$ kubectl --namespace monitoring port-forward svc/alertmanager-main 9093
Forwarding from 127.0.0.1:9093 -> 9093
Forwarding from [::1]:9093 -> 9093
Handling connection for 9093
...
````



<!-- Для деплоя приложения создадим отдельный файл и применим его:

[deploy-app](./DiplomWork/deploy-app/app-deployment.yaml) -->

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.
5. Atlantis или terraform cloud или ci/cd-terraform
# допиши отчет

---

## <a name="Деплой инфраструктуры в terraform pipeline">Деплой инфраструктуры в terraform pipeline</a>

Нам нужен custom image teamcity-agent с kubectl and terraform. Создадим его и поместим в свой docker repo:

Перейдём в папку custom-tc и выполним:

```bash

docker build -t nikogorelov/my-teamcity-agent-with-kubectl-terraform:2022.10.1 .
[1]+  Выход 1            docker build -t nikogorelov/my-teamcity-agent-with-kubectl
Sending build context to Docker daemon  90.23MB
Step 1/4 : FROM jetbrains/teamcity-agent:2022.10.1-linux-sudo
 ---> e4e1fa029b83
Step 2/4 : USER root
 ---> Running in bbf86e524072
Removing intermediate container bbf86e524072
 ---> 8424fae4b448
Step 3/4 : RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&     install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&     rm kubectl
 ---> Running in 05dd518032d9
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   138  100   138    0     0    295      0 --:--:-- --:--:-- --:--:--   294
100 55.8M  100 55.8M    0     0  13.2M      0  0:00:04  0:00:04 --:--:-- 19.5M
Removing intermediate container 05dd518032d9
 ---> 00f6d80ac5ac
Step 4/4 : COPY terraform /usr/local/bin/
 ---> 9144d02e4e58
Successfully built 9144d02e4e58
Successfully tagged nikogorelov/my-teamcity-agent-with-kubectl-terraform:2022.10.1

```

Пушим в личный docker-repo:

```bash

nimda@vm1:custom-tc$ docker push nikogorelov/my-teamcity-agent-with-kubectl-terraform:2022.10.1
The push refers to repository [docker.io/nikogorelov/my-teamcity-agent-with-kubectl-terraform]
a7bcec7ab6a7: Pushed 
7eff99156721: Pushed 
f403b424a9b9: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
47d9a0a040f3: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
f6d61128209c: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
19f1bbe3a06a: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
5b52b5406db5: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
859128f7a878: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
c645ad3d930a: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
3dbef38f68a1: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
c6b1a079f1fd: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
81a1f95d0d36: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
ffc620469d7f: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
f4462d5b2da2: Mounted from nikogorelov/my-teamcity-agent-with-kubectl 
2022.10.1: digest: sha256:c5a26c30f28a310525dffa931cf324f632b3769d3f4c6efaa0a4d636f9e2f6ff size: 3262
nimda@vm1:custom-tc$ 

```

![](./DiplomWork/img/my-own-tcagent-with-kubectl-terraform.png)



Для CI/CD разворачиваем ещё два инстанса:
1. teamcity-server
2. teamcity-agent со своим образом

Использование образов, оптимизированных для использования Docker, обусловлено тем, что для работы агентов Teamcity
необходим демон Docker для сборки образов на основе Dockerfile и отправки их в регистр. В образах, оптимизированных
для запуска Docker-контейнеров демон Docker уже установлен, что экономит нам ресурсы.

 С помощью ansible устанавливаем teamcity сервер и агент. Производим первоначальную настройку:

[==deploy-tc.ansible.yaml==](./DiplomWork/ansible/infrastructure/playbooks/deploy-tc.ansible.yaml)

<details>
<summary>ansible-playbook -i inventory/hosts.yaml playbooks/deploy-tc.ansible.yaml </summary>

```bash
nimda@vm1:infrastructure$ ansible-playbook -i inventory/hosts.yaml playbooks/deploy-tc.ansible.yaml 

PLAY [Deploy TeamCity Server] *********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************************
ok: [teamcity-server]

TASK [Install TeamCity server] ********************************************************************************************************************
ok: [teamcity-server]

PLAY [Deploy TeamCity Agent] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************************
ok: [teamcity-agent]

TASK [Ensure .kube directory exists on host] ******************************************************************************************************
ok: [teamcity-agent]

TASK [Copy kubeconfig to host if needed] **********************************************************************************************************
ok: [teamcity-agent]

TASK [Create Teamcity Agent folder] ***************************************************************************************************************
ok: [teamcity-agent]

TASK [Install TeamCity Agent from Docker image] ***************************************************************************************************
changed: [teamcity-agent]

PLAY RECAP ****************************************************************************************************************************************
teamcity-agent             : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
teamcity-server            : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

</details>
<br>

Заходим на teamcity-server и начинаем первоначальную настройку:

![](./DiplomWork/img/tc-begin-1.png)  

Выбрали базу данных по умолчанию. Выбор других для проекта избыточно;

![](./DiplomWork/img/tc-begin-2.png)  

Соглашаемся с лицензионным соглашением. Галочку про отправку анонимных данных можно убрать;

![](./DiplomWork/img/tc-begin-3.png)  

Создаем административную учетку;

![](./DiplomWork/img/tc-begin-4.png)  

Сразу же логинимся;

![](./DiplomWork/img/tc-begin-5.png)  

И первое что нам нужно сделать - это авторизовать агента, который и будет выполнять сборки CI/CD;

![](./DiplomWork/img/tc-begin-6.png)  

Дожидаемся изменения статуса на зелёный "Authorized"

![](./DiplomWork/img/tc-begin-7.png)  

Теперь можно создавать проекты по сборке и доставке;










<!-- ![](./DiplomWork/img/tc-begin-8.png)  
![](./DiplomWork/img/tc-begin-9.png)  
![](./DiplomWork/img/tc-begin-10.png)  
![](./DiplomWork/img/tc-begin-11.png)   -->






---

## <a name="Установка и настройка CI/CD">Установка и настройка CI/CD</a>

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

### Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.


Начнём по порядку. Добавим git репозиторий, изменения которого будут отслеживаться:

![](./DiplomWork/img/tc-web-app-1.png)  

`Fetch URL` - собственно наш репозиторий для отслеживания;  
`Username`  - логин github репозитория;  
`Password/access token` - токен заранее создаётся в интерфейсе github. При создании указываются права доступа и срок действия токена;  
`Branch specification`  - добавляется для отслеживания изменения в любой из веток проекта github;  

![](./DiplomWork/img/tc-web-app-2.png)  

На вкладке `Build features` нужно добавить расширение `Docker Registry Connection`. Иначе teamcity не будет работать с docker;

![](./DiplomWork/img/tc-web-app-3.png)  

Добавим переменные, которые будут использоваться в скриптах сборки, а также с целью скрыть чувствительные данные;

![](./DiplomWork/img/tc-web-app-4.png)  

На вкладке `Triggers` добавим условия при которых будет запускаться сборка;

![](./DiplomWork/img/tc-web-app-5.png)  

Теперь займёмся этапами сборки. Так как в корне нашего проекта имеется Dockerfile, то первое что нужно сделать это 
нажать на кнопку автоматического определения шагов сборки. Teamcity увидит Dockerfile и предложит автоматически создать
первый этап сборки docker образа, но мы его потом сместим. Воспользуемся этим;

![](./DiplomWork/img/tc-web-app-6.png)  

Следующим этапом залогинимся на нашем внешнем docker репозитории. Используем custom скрипт. В скрипте используем ранее созданные переменные;

```bash
echo "%env.DOCKER_REGISTRY_PASSWORD%" | docker login -u "%env.DOCKER_REGISTRY_USERNAME%" --password-stdin
```
В конце команды нужно указывать свой репозиторий, но мы используем dockerhub. Он подставит автоматически;

![](./DiplomWork/img/tc-web-app-7.png)  

Третьим этапов будем определять наличие тега у коммита. Если его нет, то сборка docker образа будет проходить с тегом по умолчанию "latest". В случае наличия тега сборка будет с тегом из коммита;

```bash

#!/bin/bash
set -e

# Загружаем все теги (на случай shallow clone)
git fetch --tags

# Получаем тег, указывающий на текущий коммит
tag=$(git tag --points-at HEAD | head -n1)

# Если тег не найден — используем 'latest'
if [ -z "$tag" ]; then
  tag="latest"
  echo "No tag found on current commit. Using 'latest'."
else
  echo "Current commit tag: '$tag'"
fi

# Экспортируем параметр в TeamCity
echo "##teamcity[setParameter name='env.COMMIT_TAG' value='$tag']"

```

![](./DiplomWork/img/tc-web-app-8.png)  

Тот автоматически созданный первый этап нужно переместить на третий этап сборки и немного дополнить. 
В строке имени создаваемого образа укажем наши параметры "nikogorelov/gnn-diploma-netology:%env.COMMIT_TAG%"

![](./DiplomWork/img/tc-web-app-9.png)  

Теперь пушим ранее собранный образ. Тут в поле image name, указываем тоже самое, что и на предыдущем шаге;

![](./DiplomWork/img/tc-web-app-10.png)  

В заключении делаем deploy образа в k8s кластер с новым тегом. Если тег остутсвует, то и deploy не происходит.

ВАЖНО: Перед deploy in k8s необходимо убедиться, что [приложение](./DiplomWork/deploy-app/app-deployment.yaml) уже развёрнуто и namespace существует!!!


```bash

#!/bin/bash
set -e

# Если тег не найден — используем 'latest'
if [ "%env.COMMIT_TAG%" == "latest" ]; then
  echo "Not a Git tag — skipping deployment."
  exit 0
else
  echo "Current commit tag: %env.COMMIT_TAG%"
fi

IMAGE="%env.REGISTRY_IMAGE%:%env.COMMIT_TAG%"

echo "Deploying $IMAGE to Kubernetes"

kubectl set image deploy/gnn-diploma-app app="$IMAGE" --namespace=default

```

![](./DiplomWork/img/tc-web-app-11.png)  


По итогу получилось 5 этапов, которые идут друг за другом и если один из этапов завершился ошибкой, то вся сборка прерывается;

![](./DiplomWork/img/tc-web-app-12.png)  

Проверяем корректность настройки всего. Для этого достаточно сделать коммит и запушить в наш [git](https://github.com/gorelovniko/diploma-webapp).
Для начала сделаем не добавляя тега; 

![](./DiplomWork/img/tc-web-app-13.png)  

В течении минуты сборка должна начаться, что видно на скриншоте;

![](./DiplomWork/img/tc-web-app-14.png)  
![](./DiplomWork/img/tc-web-app-15.png)  
![](./DiplomWork/img/tc-web-app-16.png)  
![](./DiplomWork/img/tc-web-app-17.png)  
![](./DiplomWork/img/tc-web-app-18.png)  

Как видно из скриншотов выше всё прошло как планировалось. Тег не обнаружен, поэтому docker образ собрался с тегом latest, 
а приложение не задеплоилось;

Теперь добавим тег;

![](./DiplomWork/img/tc-web-app-19.png)  
![](./DiplomWork/img/tc-web-app-20.png)  
![](./DiplomWork/img/tc-web-app-21.png)  
![](./DiplomWork/img/tc-web-app-22.png)  
![](./DiplomWork/img/tc-web-app-23.png)  
![](./DiplomWork/img/tc-web-app-24.png)  

И вот снова отработало так как нам надо. Цели достигнуты;

### Ожидаемый результат достигнут:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---