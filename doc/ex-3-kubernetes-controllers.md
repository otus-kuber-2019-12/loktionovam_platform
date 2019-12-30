# EX-3 Kubernetes controllers. ReplicaSet, Deployment, DaemonSet

* [x] Основное задание: написать **ReplicaSet** для **hipster-frontend** и **hipster-paymentservice**. Проверить управление подами через ReplicaSet. Проверить обновление через ReplicaSet, объяснить, почему обновление ReplicaSet не повлекло обновление подов.

* [x] Основное задание: написать **Deployment** для **hipster-frontend** и **hipster-paymentservice**. Проверка **Rolling Update** через написанные деплойменты. Проверка отката.
* [x] Задание со (*): реализовано **Blue-green deployment** и **Reverse Rolling Update**
* [x] Основное задание: работа с **probes**. Проверка обновления приложения при некорректной работе приложения, автоатический откат приложения.
* [x] Задание со (*): написать **DaemonSet** для установки **prometheus node exporter**
* [x] Задание с (**): развертывание **node exporter** на мастер ноды. Работа с taints и tolerations

## EX-3.1 Что было сделано

* Развернут kind с тремя воркер-нодами и тремя мастер-нодами.
* Запущен **replicaset** для **hipster-frontend**, проверено обновление репликасета, проверено автоматический перезапуск подов при удалении.
  Почему обновление **ReplicaSet** не повлекло обновление запущенных **pod**: из документации к **ReplicaSet**
  <https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#example>
  
  ```plain
  Once the original is deleted, you can create a new ReplicaSet to replace it. As long as the old and new .spec.selector are the same,
  then the new one will adopt the old Pods. However, it will not make any effort to make existing Pods match a new, different pod template.
  To update Pods to a new spec in a controlled way, use a Deployment, as ReplicaSets do not support a rolling update directly.
  ```
  
  то есть **ReplicaSet** не умеет обновлять существующие **Pod** при изменении тэга образа. Для этих целей, нужно использовать **Deployment**.

* Запущен **deployment** для **hipster-frontend**, проверено обновление деплоймента.
* Собран из запушен в dockerhub образ **hipster-paymentservice**.
* Написаны и проверены манифесты для **Blue green deploy** и **Reverse Rolling update**.
* Проверено обновление "плохого" приложения, через изменение **readiness probe** для **hipster-frontend**
* Написан DaemonSet манифест для node-exporter с поддержкой развертывания на control plane ноды:
  **Control plane nodes** имеют такой **taints**:
  
  ```yaml
      taints:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
  ```
  
  который означает, что **pod** не будет запланирован на master нодах.
  
  Из документации по **Taints and Tolerations** <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/>:
  
  ```plain
  The taint has key key, value value, and taint effect NoSchedule. This means that no pod will be able to schedule onto node1 unless it has a matching toleration.
  ```
  
  то есть, чтобы отключить **NoSchedule**, и запустить **pod** на master нодах, то нужно добавить **tolerations**:
  
  ```yaml
        tolerations:
          - key: node-role.kubernetes.io/master
            effect: NoSchedule
  ```

## EX-3.2 Как запустить проект

Применить манифесты из каталога `kubernetes-controllers`:

```bash
kubectl apply -f paymentservice-deployment-bg.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f node-exporter-daemonset.yaml
```

## EX-3.3 Как проверить проект

* Проверить запущенные deployment:
  
  ```bash
  kubectl get deployments.apps 
  NAME             READY   UP-TO-DATE   AVAILABLE   AGE
  frontend         3/3     3            3           123m
  paymentservice   3/3     3            3           3h20m
  ```

* Проверить запущенные daemonset:

  ```bash
  kubectl get daemonsets.apps 
  NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
  node-exporter   6         6         6       6            6           <none>          101m
  ```

## EX-3.4 Как начать пользоваться проектом

* Получить метрики отдаваемые node exporter:

  ```bash
  kubectl port-forward <node-exporter-pod-here> 9100:9100
  curl localhost:9100/metrics
  ```
