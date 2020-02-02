# EX-8 Шаблонизация манифестов Kubernetes

* [EX-8 Шаблонизация манифестов Kubernetes](#ex-8-%d0%a8%d0%b0%d0%b1%d0%bb%d0%be%d0%bd%d0%b8%d0%b7%d0%b0%d1%86%d0%b8%d1%8f-%d0%bc%d0%b0%d0%bd%d0%b8%d1%84%d0%b5%d1%81%d1%82%d0%be%d0%b2-kubernetes)
  * [EX-8.1 Что было сделано](#ex-81-%d0%a7%d1%82%d0%be-%d0%b1%d1%8b%d0%bb%d0%be-%d1%81%d0%b4%d0%b5%d0%bb%d0%b0%d0%bd%d0%be)
  * [EX-8.2 Как запустить проект](#ex-82-%d0%9a%d0%b0%d0%ba-%d0%b7%d0%b0%d0%bf%d1%83%d1%81%d1%82%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-8.3 Как проверить проект](#ex-83-%d0%9a%d0%b0%d0%ba-%d0%bf%d1%80%d0%be%d0%b2%d0%b5%d1%80%d0%b8%d1%82%d1%8c-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82)
  * [EX-8.4 Как начать пользоваться проектом](#ex-84-%d0%9a%d0%b0%d0%ba-%d0%bd%d0%b0%d1%87%d0%b0%d1%82%d1%8c-%d0%bf%d0%be%d0%bb%d1%8c%d0%b7%d0%be%d0%b2%d0%b0%d1%82%d1%8c%d1%81%d1%8f-%d0%bf%d1%80%d0%be%d0%b5%d0%ba%d1%82%d0%be%d0%bc)

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
