# Шпаргалка по командам

## minikube

```bash
minikube start
```

## kind

```bash
kind create cluster --wait 300s
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
  ```
