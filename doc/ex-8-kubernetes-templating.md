# EX-8 Шаблонизация манифестов Kubernetes

## EX-8.1 Что было сделано

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

## EX-8.3 Как проверить проект

## EX-8.4 Как начать пользоваться проектом
