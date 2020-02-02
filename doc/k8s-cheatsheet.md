# Шпаргалка по командам

* [Шпаргалка по командам](#%d0%a8%d0%bf%d0%b0%d1%80%d0%b3%d0%b0%d0%bb%d0%ba%d0%b0-%d0%bf%d0%be-%d0%ba%d0%be%d0%bc%d0%b0%d0%bd%d0%b4%d0%b0%d0%bc)
  * [minikube](#minikube)
  * [kind](#kind)
  * [kubectl](#kubectl)
  * [Helm](#helm)

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
