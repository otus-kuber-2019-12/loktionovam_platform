# EX-8 Шаблонизация манифестов Kubernetes

* [EX-8 Шаблонизация манифестов Kubernetes](#ex-8-%d0%a8%d0%b0%d0%b1%d0%bb%d0%be%d0%bd%d0%b8%d0%b7%d0%b0%d1%86%d0%b8%d1%8f-%d0%bc%d0%b0%d0%bd%d0%b8%d1%84%d0%b5%d1%81%d1%82%d0%be%d0%b2-kubernetes)
  * [EX-8.1 Что было сделано](#ex-81-%d0%a7%d1%82%d0%be-%d0%b1%d1%8b%d0%bb%d0%be-%d1%81%d0%b4%d0%b5%d0%bb%d0%b0%d0%bd%d0%be)
  * [EX-8.2 Как запустить проект](#ex-82-%d0%9a%d0%b0%d0%ba-%d0%b7%d0%b0%d0%bf%d1%83%d1%81%d1%82%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-8.3 Как проверить проект](#ex-83-%d0%9a%d0%b0%d0%ba-%d0%bf%d1%80%d0%be%d0%b2%d0%b5%d1%80%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-8.4 Как начать пользоваться проектом](#ex-84-%d0%9a%d0%b0%d0%ba-%d0%bd%d0%b0%d1%87%d0%b0%d1%82%d1%8c-%d0%bf%d0%be%d0%bb%d1%8c%d0%b7%d0%be%d0%b2%d0%b0%d1%82%d1%8c%d1%81%d1%8f-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82%d0%be%d0%bc)

## EX-8.1 Что было сделано

* В скрипты бутстрапа добавлена установка и настройка gcloud, установка terraform, tflint, helm3, helmfile, kubecfg, qbec, jsonnet
* Добавлена конфигурация terraform для развертывания GKE
* Добавлен манифест `ClusterIssuer` для cert-manager
* Добавлены `values.yaml` для `chartmuseum`
* (*) Изучение работы с `chartmuseum`
* Установлен `harbor` со включенным TLS и валидным сертификатом
* (*) Написан `helmfile` для установки `nginx-ingress`, `cert-manager`, `harbor`
* Добавлены `hipster-shop` и `frontend` helm chart
* (*) Использован redis community chart в качестве зависимости для `hipster-shop`
* Добавлен файл с секретами в `frontend` chart, секрет добавлен в k8s с помощью `helm secrets`, описана работа с секретами.
* Сервисы `paymentservice`, `shippingservice` шаблонизированы через `kubecfg`
* (*) Сервис `adservice` шаблонизирован через `qbec`
* Сервис `cartservice` шаблонизирован через `kustomize`

Описание работы с `helm secrets`:

* Проверить секреты можно командой:

  ```bash
  get secrets sh.helm.release.v1.frontend.v2  -n hipster-shop  -o=jsonpath='{.data.release}' | base64 --decode
  ```

* Способ использования в CI/CD аналогичен `ansible-vault` - в репозитории хранятся зашифрованные данные, а в переменных окружения CI/CD есть ключ `(masked, protected)` для расшифровки этих данных в процессе исполнения задач конвейера.
* Пользоваться секретами, которые "лежат" в репозитории не очень хорошая практика, т.к. можно их случайно закоммитить и придется переписывать историю удаленного репозитория, что может повлиять на остальных участников разработки. С другой стороны, хранить их вне репозитория, может быть неудобно, поэтому как компромиссное решение можно:
  * Создать каталог `secrets` внутри репозитория в котором будет отдельный `.gitignore`:

    ```bash
    # считаем, что все данные в этом каталоге не должны попадать в удаленный гит-репозиторий.
    cat secrets/.gitignore
    *
    !.gitignore
    ```

    Это явно укажет, в каком каталоге секретные данные (не размазывая их по всему репозиторию) и снизит риск случайных ошибок в корневом `.gitignore` файле. Например, если переименовать `secrets` в `ssl`, то исключения для этого каталога сохранятся без дополнительных правок `.gitignore`.

  * Использовать хуки гита, для фильтрации секретных данных <https://github.com/futuresimple/helm-secrets#important-tips>

    Эти два способа можно комбинировать друг с другом.

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
  kubectl apply -f kubernetes-templating/nginx-ingress/namespace.yaml
  helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress --version=1.11.1
  ```

* Установить `cert-manager`

  ```bash
  helm repo add jetstack https://charts.jetstack.io
  kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
  kubectl apply -f kubernetes-templating/cert-manager/namespace.yaml
  kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
  helm upgrade --install cert-manager jetstack/cert-manager --wait --namespace=cert-manager --version=0.9.0
  kubectl apply -f kubernetes-templating/cert-manager/cluster-issuer.yaml
  ```

* Установить `chartmuseum`

  ```bash
  kubectl apply -f kubernetes-templating/chartmuseum/namespace.yaml
  helm upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.3.2 -f kubernetes-templating/chartmuseum/values.yaml
  ```

* (*) Работа с `chartmuseum`. Для проверки написан скрипт `misc/scripts/check_chartmuseum.sh`, который создает тестовый чарт, загружает его в `chartmuseum`, выводит информацию о загруженном артефакте, подключает репозиторий с `chartmuseum`, в режиме `dry-run` "устанавливает" чарт в k8s, а затем удаляет его из `chartmuseum`

  ```bash
  # Предполагается, что доступ к API разрешен (см. values.yaml для chartmuseum)
  misc/scripts/check_chartmuseum.sh
  Create test helm package check_chartmuseum
  Creating check_chartmuseum
  Successfully packaged chart and saved it to: /tmp/tmp.yHpOUv1FC0/check_chartmuseum/check_chartmuseum-0.1.0.tgz
  Upload test helm package check_chartmuseum-0.1.0.tgz to the https://chartmuseum.35.240.65.117.nip.io/api/charts
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
  Remove check_chartmuseum from https://chartmuseum.35.240.65.117.nip.io
  {
    "deleted": true
  }
  Remove chartmuseum repo from helm repositories list
  "chartmuseum" has been removed from your repositories
  ```

* Установить `harbor`

  ```bash
  helm repo add harbor https://helm.goharbor.io
  kubectl apply -f kubernetes-templating/harbor/namespace.yaml
  helm upgrade --install harbor harbor/harbor --atomic --namespace=harbor --version=1.1.2  -f kubernetes-templating/harbor/values.yaml
  ```

* Установить `harbor` с помощью `helmfile`

  ```bash
  cd kubernetes-templating/helmfile/
  helmfile --log-level=debug --interactive apply
  ```

* Установить `hipster-shop`

  ```bash
  kubectl create ns hipster-shop
  helm upgrade --install hipster-shop --atomic kubernetes-templating/hipster-shop --namespace hipster-shop
  # helm dep update kubernetes-templating/hipster-shop
  ```

* Создать `helm` пакет для `hipster-shop`

  ```bash
  helm package kubernetes-templating/hipster-shop
  ```

* Установить компоненты магазина `paymentservice`, `shippingservice` через `kubecfg`:

  ```bash
  cd kubernetes-templating/kubecfg/
  kubecfg update services.jsonnet --namespace hipster-shop
  ```

* Установить компоненту магазина `adservice` через `qbec` (краткое `how-to` по `qbec` здесь <https://habr.com/ru/post/481662/#qbec>)

  ```bash
  cd kubernetes-templating/jsonnet/qbec/adservice/
  qbec show default
  qbec apply default
  ```

* Установить компоненту магазина `cartservice` через `kustomize`

  ```bash
  kubectl kustomize kubernetes-templating/kustomize/overrides/default/  | kubectl apply -f -
  ```

## EX-8.3 Как проверить проект

* `harbor` с загруженными чартами будет доступен по адресу:

  ```bash
  kubectl get ingress -n harbor  -o jsonpath='{.items[*].spec.rules[*].host}'
  ```

* `hipster-shop` будет доступен по адресу:

  ```bash
  kubectl get ingress -n hipster-shop  -o jsonpath='{.items[*].spec.rules[*].host}'
  ```

## EX-8.4 Как начать пользоваться проектом
