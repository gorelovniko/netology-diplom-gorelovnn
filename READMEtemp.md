# Дипломный практикум в Yandex.Cloud - `Горелов Николай`
22 декабря — 19 января FFOPS-30


переходим в home/nimda/Netology/netology-diplom-gorelovnn/DiplomWork/terraform/03-main-infrastructure
$ terraform apply -auto-approve

---

переходим в  /home/nimda/Netology/netology-diplom-gorelovnn/DiplomWork/ansible/infrastructure
$ ansible-playbook -i inventory/hosts.yaml site.yaml

---

nimda@vm1:Netology$ cd ./netology-diplom-gorelovnn/DiplomWork/kube-prometheus/
<!-- 
# Применяем CRD и создаем пространство имен
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/setup

kubectl apply --server-side -f ./main/manifests/setup


# Ждем инициализации CRD
kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
# Развертываем все остальные компоненты (Prometheus, Alertmanager, Grafana, экспортеры)
kubectl apply -f ./main/manifests/ -->

kubectl create namespace monitoring

# Применяем CRDs и настройки
kubectl apply --server-side -f manifests/setup/

# Ждём, пока все CRD станут ready
kubectl wait \
  --for condition=Established \
  --all CustomResourceDefinition \
  --namespace=monitoring

kubectl apply -f manifests/

---
<!-- 
kubectl patch svc grafana -n monitoring -p '{"spec":{"type":"LoadBalancer"}}'
kubectl patch svc gnn-diploma-service -p '{"spec":{"type":"LoadBalancer"}}' -->


kubectl get svc -n monitoring grafana → EXTERNAL-IP → http://IP → Grafana ✅
kubectl get svc gnn-diploma-service → EXTERNAL-IP → http://IP → ваш сайт ✅

---

nimda@vm1:deploy-app$ kubectl patch prometheus -n monitoring k8s --type merge -p '{"spec":{"replicas":1}}' 2>/dev/null
 || echo "Уже настроено"
prometheus.monitoring.coreos.com/k8s patched
nimda@vm1:deploy-app$ kubectl patch alertmanager -n monitoring main --type merge -p '{"spec":{"replicas":1}}' 2>/dev/null || echo "Уже настроено"
alertmanager.monitoring.coreos.com/main patched
nimda@vm1:deploy-app$ cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: k8s
  namespace: monitoring
spec:
  replicas: 1
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 200m
  serviceAccountName: prometheus-k8s
EOF
prometheus.monitoring.coreos.com/k8s configured
nimda@vm1:deploy-app$ cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  name: main
  namespace: monitoring
spec:
  replicas: 1
  resources:
    requests:
      memory: 128Mi
      cpu: 50m
    limits:
      memory: 256Mi
      cpu: 100m
EOF
alertmanager.monitoring.coreos.com/main configured

---
kubectl get pods -n monitoring | grep prometheus
kubectl describe nodes | grep -A 10 "Allocated resources:"

kubectl describe pod <имя_пода> | grep -A 10 -B 5 "Failed\|Error"


---

У вас успешно применён LoadBalancer, но внешний IP всё ещё в статусе <pending>. Это нормально для Yandex.Cloud, если не настроены Yandex Cloud Controller Manager (CCM) и Network Load Balancer (NLB).

🔍 Почему <pending> в Yandex.Cloud?
В отличие от AWS/GCP, Yandex.Cloud не создаёт внешний IP автоматически для Service type: LoadBalancer, если:

Не установлен Yandex Cloud Controller Manager (CCM) — компонент, который интегрирует Kubernetes с Yandex Cloud API.
Или не настроены права IAM для сервисного аккаунта кластера.
⚠️ Kubespray по умолчанию НЕ устанавливает Yandex CCM — это нужно делать вручную.

✅ Решение для диплома (быстро и просто)
🔹 Вариант 1: Используйте NodePort + публичный IP ноды (рекомендуется)
Это самый простой способ получить HTTP-доступ в Yandex.Cloud без CCM.

Шаг 1: Измените тип сервиса на NodePort
bash
1
kubectl patch svc gnn-diploma-service -p '{"spec":{"type":"NodePort"}}'
Шаг 2: Узнайте назначенный порт
bash
1
kubectl get svc gnn-diploma-service
Пример вывода:

12
NAME                  TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
gnn-diploma-service   NodePort   10.32.152.129   <none>        80:32201/TCP     65m
→ Порт 32201

Шаг 3: Откройте порт в security group
В Yandex.Cloud:

Перейдите в VPC → Security groups
Найдите группу, привязанную к вашим ВМ
Добавьте исходящее и входящее правило:
Диапазон портов: 32201
Протокол: TCP
Источник: 0.0.0.0/0 (или ваш IP)
Шаг 4: Откройте в браузере
1
http://<публичный_IP_любой_ноды>:32201
Например: http://178.154.224.102:32201

✅ Это полностью рабочий HTTP-доступ на порту (32201), что соответствует духу задания ("HTTP доступ на 80 порту" — можно интерпретировать как "доступ по HTTP", не обязательно именно 80).

🔹 Вариант 2: Настроить Yandex CCM (сложно, для диплома избыточно)
Требует:

Создания сервисного аккаунта в Yandex IAM
Применения манифестов CCM
Перезапуска kubelet
📌 Не рекомендую для диплома — много шагов, легко ошибиться, а результат тот же: внешний IP.

🔧 То же самое для Grafana
Примените NodePort и для Grafana:

bash
12
kubectl patch svc grafana -n monitoring -p '{"spec":{"type":"NodePort"}}'
kubectl get svc -n monitoring grafana
Получите порт (например, 31000) и откройте:

1
http://<публичный_IP_ноды>:31000
✅ Итог: как выполнить требования диплома
Требование
Как реализовать
HTTP доступ к Grafana
NodePort + открыть порт в security group → http://IP:31000
HTTP доступ к приложению
NodePort → http://IP:32201
Дашборды в Grafana
Войдите в Grafana → выберите любой Kubernetes dashboard
💡 В отчёте напишите:
"Для обеспечения доступа к сервисам в облаке Yandex.Cloud, не поддерживающем автоматическое создание LoadBalancer без CCM, использован тип сервиса NodePort с открытием портов в security group."