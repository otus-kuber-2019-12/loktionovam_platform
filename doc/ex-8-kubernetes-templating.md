# EX-8 Шаблонизация манифестов Kubernetes

* [EX-8 Шаблонизация манифестов Kubernetes](#ex-8-%d0%a8%d0%b0%d0%b1%d0%bb%d0%be%d0%bd%d0%b8%d0%b7%d0%b0%d1%86%d0%b8%d1%8f-%d0%bc%d0%b0%d0%bd%d0%b8%d1%84%d0%b5%d1%81%d1%82%d0%be%d0%b2-kubernetes)
  * [EX-8.1 Что было сделано](#ex-81-%d0%a7%d1%82%d0%be-%d0%b1%d1%8b%d0%bb%d0%be-%d1%81%d0%b4%d0%b5%d0%bb%d0%b0%d0%bd%d0%be)
  * [EX-8.2 Как запустить проект](#ex-82-%d0%9a%d0%b0%d0%ba-%d0%b7%d0%b0%d0%bf%d1%83%d1%81%d1%82%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-8.3 Как проверить проект](#ex-83-%d0%9a%d0%b0%d0%ba-%d0%bf%d1%80%d0%be%d0%b2%d0%b5%d1%80%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-8.4 Как начать пользоваться проектом](#ex-84-%d0%9a%d0%b0%d0%ba-%d0%bd%d0%b0%d1%87%d0%b0%d1%82%d1%8c-%d0%bf%d0%be%d0%bb%d1%8c%d0%b7%d0%be%d0%b2%d0%b0%d1%82%d1%8c%d1%81%d1%8f-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82%d0%be%d0%bc)

## EX-8.1 Что было сделано

* В скрипты бутстрапа добавлена установка и настройка gcloud, установка terraform, tflint, helm3
* Добавлена конфигурация terraform для развертывания GKE
* Добавлен манифест `ClusterIssuer` для cert-manager
* Добавлены `values.yaml` для `chartmuseum`
* (*) Изучение работы с `chartmuseum`

## EX-8.2 Как запустить проект

* Запустить кластер GKE

  ```bash
  cd infra/kubernetes/terraform
  terraform init
  terraform apply
  cd gke
  terraform init
  terraform apply
  ....
  Outputs:

  kubernetes_endpoint = ip_address_here
  ```

* Настроить kubectl на использование GKE

  ```bash
  gcloud beta container clusters get-credentials primary --zone <zone_here>
  ```

* Установить nginx-ingress

  ```bash
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm repo list
  helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress --version=1.11.1
  ```

* Установить `cert-manager`

  ```bash
  helm repo add jetstack https://charts.jetstack.io
  kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
  kubectl create ns cert-manager
  kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
  helm upgrade --install cert-manager jetstack/cert-manager --wait --namespace=cert-manager --version=0.9.0
  kubectl apply -f kubernetes-templating/cert-manager/cluster-issuer.yaml
  ```

* Установить `chartmuseum`

  ```bash
  kubectl create ns chartmuseum
  helm upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.3.2 -f kubernetes-templating/chartmuseum/values.yaml
  ```

* (*) Работа с `chartmuseum`. Для проверки написан скрипт `misc/scripts/check_chartmuseum.sh`, который создает тестовый чарт, загружает его в `chartmuseum`, выводит информацию о загруженном артефакте, подключает репозиторий с `chartmuseum`, в режиме `dry-run` "устанавливает" чарт в k8s, а затем удаляет его из `chartmuseum`

  ```bash
  # Предполагается, что доступ к API разрешен (см. values.yaml для chartmuseum)
  misc/scripts/check_chartmuseum.sh
  Create test helm package check_chartmuseum
  Creating check_chartmuseum
  Successfully packaged chart and saved it to: /tmp/tmp.yHpOUv1FC0/check_chartmuseum/check_chartmuseum-0.1.0.tgz
  Upload test helm package check_chartmuseum-0.1.0.tgz to the https://chartmuseum.35.195.194.134.nip.io/api/charts
  Get information about uploaded chart
  [
    {
      "name": "check_chartmuseum",
      "version": "0.1.0",
      "description": "A Helm chart for Kubernetes",
      "apiVersion": "v2",
      "appVersion": "1.16.0",
      "urls": [
        "charts/check_chartmuseum-0.1.0.tgz"
      ],
      "created": "2020-02-02T14:07:19.521814922Z",
      "digest": "9644296cefc22aa8e4be717a85d648e5524d8b17bc43c75a4af10673ee9c9902"
    }
  ]
  Try to add chartmuseum repo to helm and install test chart
  "chartmuseum" has been added to your repositories
  NAME: 0.1.0
  LAST DEPLOYED: Sun Feb  2 17:20:29 2020
  NAMESPACE: default
  STATUS: pending-install
  REVISION: 1
  HOOKS:
  ---
  # Source: check_chartmuseum/templates/tests/test-connection.yaml
  apiVersion: v1
  ...
  ...
  ...
  Remove check_chartmuseum from https://chartmuseum.35.195.194.134.nip.io
  {
    "deleted": true
  }
  Remove chartmuseum repo from helm repositories list
  "chartmuseum" has been removed from your repositories
  ```

## EX-8.3 Как проверить проект

## EX-8.4 Как начать пользоваться проектом
