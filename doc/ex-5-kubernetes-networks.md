# EX-5 Сетевое взаимодействие Pod, сервисы

* [x] Основное задание: работа с тестовым веб-приложением (добавление проверок pod, создание объекта deployment, добавление сервисов в кластер (ClusterIP), включение режима балансировки IPVS)
* [x] Основное задание: доступ к приложению извне кластера (установка metallb в layer2 режиме, добавление сервиса LoadBalancer, установка Ingress-контроллера и прокси `ingress-nginx`, создание правил `Ingress`)
* [x] Задание со (*): сделать сервис LoadBalancer, который откроет доступ к CoreDNS снаружи кластера
* [x] Задание со (*): сделать доступным `dashboard` через nginx ingress
* [x] Задание со (*): сделать канареечное развертывание приложения `web` по HTTP заголовку, через `nginx ingress`

## EX-5.1 Что было сделано

* Написан манифест для создания сервиса типа `ClusterIP` для балансировки трафика приложения web
* Включено и проверено использование `ipvs` вместо `iptables`
* Установлен и настроен metallb для создания сервиса типа `LoadBalancer`
* (*) Написан манифест для `LoadBalancer`, который выставляет CoreDNS наружу кластера
* В проект добавлены линтеры для shell, python, yaml файлов, исправлены предупреждения и ошибки
* Добавлены манифесты для `nginx ingress` работающего через `MetalLB` и проксирующего запросы на web приложение
* Следующая конфигурация валидна и проверка всегда (если в контейнере есть шелл, `ps`, `grep`) будет иметь код возврата `0`

```yaml
livenessProbe:
  exec:
    command:
      - 'sh'
      - '-c'
      - 'ps aux | grep my_web_server_process'
```

TODO: уточнить, когда имеет смысл такая сложная конструкция.

* (*) Написаны манифесты, которые делают доступным снаружи `kubernetes dashboard`
* (*) Собран докер образ `web-python:latest` имитирующий новую версию приложения (основной образ использует `nginx`).
  Написаны манифесты, реализующие канареечное развертывание `web-python:latest` через `nginx ingress`

## EX-5.2 Как запустить проект

* В корне проекта выполнить:

```bash
minikube start
minikube addons disable dashboard
kubectl delete clusterrolebinding kubernetes-dashboard
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml
docker build kubernetes-networks/canary/web-python/ -t loktionovam/web-python:latest
docker push loktionovam/web-python:latest
find kubernetes-networks -name "*.yaml" -exec kubectl apply -f  '{}' \;
```

## EX-5.3 Как проверить проект

* Линтеры должны отработать без ошибок:

  ```bash
  misc/scripts/lint_project.py
  ...
  Lint project: OK
  ```

* Добавить маршрут на хосте до ВМ с minikube

  ```bash
  sudo ip r add to 172.17.255.0/24 via 192.168.99.1
  ```

* Проверка доступности DNS:

  ```bash
  misc/scripts/check_external_dns_address.sh
  # Если DNS доступен снаружи, то скрипт выведет 'External CoreDNS is OK'
  web-svc-cip.default.svc.cluster.local has address 10.96.229.152
  External CoreDNS is OK
  ```

* Проверка доступности `web` приложения:

  ```bash
  misc/scripts/check_nginx_ingress_web.sh
  'Web' application (prod) is OK via nginx ingress
  ```

* Проверка доступности канареечного развертывания `web` приложения:

  ```bash
  misc/scripts/check_nginx_canary_ingress.sh
  'Web' application (v2, canary) is OK via nginx ingress
  ```

## EX-5.4 Как начать пользоваться проектом
