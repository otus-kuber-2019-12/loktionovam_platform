# Шпаргалка по командам

* [Шпаргалка по командам](#%d0%a8%d0%bf%d0%b0%d1%80%d0%b3%d0%b0%d0%bb%d0%ba%d0%b0-%d0%bf%d0%be-%d0%ba%d0%be%d0%bc%d0%b0%d0%bd%d0%b4%d0%b0%d0%bc)
  * [minikube](#minikube)
  * [kind](#kind)
  * [kubectl](#kubectl)
  * [Helm](#helm)
  * [Chartmuseum](#chartmuseum)
  * [Helm secrets](#helm-secrets)
  * [k8s API](#k8s-api)
  * [GKE](#gke)

## minikube

```bash
minikube start
```

## kind

```bash
kind create cluster --wait 300s
# или
kind create cluster --config bootstrap/k8s/kind-config.yaml
```

## kubectl

* Информация о кластере

  ```bash
  kubectl config view
  kubectl cluster-info
  ```

* Изменения в кластере

  ```bash
  kubectl apply -f some_manifest.yaml
  kubectl create -f some_manifest.yaml

  kubectl delete pod web
  kubectl delete pod --all
  ```

* Информация о ресурсах кластера

  ```bash
  # Следить за изменениями
  kubectl get pod --watch=true

  # Получить информацию о pod в yaml формате
  kubectl get pod web -o yaml

  # Получить расширенную информацию о ресурсе
  kubectl describe pod web

  # Получить токен для admin-user
  kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

  # Пример jsonpath - получить docker image для всех запущенных node-exporter
  kubectl get pods -l app=node-exporter -o=jsonpath='{.items[*].spec.containers[0].image}'
  ```

* Информация о развертывании

  ```bash
  # статус обновления для frontend
  kubectl rollout status deployment frontend --timeout=10s

  # получить список ревизий
  kubectl rollout history deployment paymentservice

  # откатиться на 4-ю ревизию
  kubectl rollout undo deployment paymentservice --to-revision 4
  ```

## Helm

* Создание **release**:

  ```bash
  helm install <chart_name> --name=<release_name>  --namespace=<namespace>
  kubectl get secrets -n <namespace> | grep <release_name>
  ```

* Обновление **release**:

  ```bash
  helm upgrade <release_name> <chart_name> --namespace=<namespace>
  kubectl get secrets -n <namespace> | grep <release_name>
  ```

* Создание или обновление **release**:

  ```bash
  helm upgrade --install <release_name> <chart_name> --namespace=<namespace>
  ```

* Добавить репозиторий, вывести список репозиториев:

  ```bash
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm repo list
  ```

## Chartmuseum

* Работу с `chartmuseum` можно посмотреть в `misc/scripts/check_chartmuseum.sh`

## Helm secrets

* Зашифровать файл:

  ```bash
  gpg --full-generate-key
  gpg -k
  sops -e -i --pgp HASH secrets.yaml
  ```

* Расшифровать файл:

  ```bash
  sops -d secrets.yaml
  # or
  helm secrets view secrets.yaml
  ```

## k8s API

```bash
export CLUSTER_NAME="minikube"
APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)
curl -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure
```

## GKE

* Настроить kubectl на использование primary кластера

  ```bash
  gcloud beta container clusters get-credentials primary --zone europe-west1-b
  ```
