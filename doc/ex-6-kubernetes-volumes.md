# EX-6 Volumes, Storages, StatefulSet

* [x] Основное задание: создание statefulset
* [x] Задание со (*): использовать `kubernetes secrets` для задания секретных данных в MinIO

## EX-6.1 Что было сделано

* Добавлен манифест `minio-statefulset.yaml`, создан StatefulSet с MinIo
* Добавлен манифест `minio-headless-service.yaml`, создан Headless Service для доступа к StatefulSet изнутри кластера
* Добавлен скрипт `misc/scripts/generate_minio_secret.sh` для генерации манифеста с секретами
* (*) Добавлено использование секретов в MinIO StatefulSet
* (*) Добавлен манифест `minio-client.yaml` и скрипт `misc/scripts/check_minio.sh` проверяющий, что секреты работают и сам MinIO сервер тоже работает

## EX-6.2 Как запустить проект

* Создать секрет для MinIO скриптом `misc/scripts/generate_minio_secret.sh`. Сам скрипт не создает секрет, а только выводит манифест в stdout:

  ```bash
  misc/scripts/generate_minio_secret.sh <minio_access_key_here> <minio_secret_key_here> | kubectl apply -f -
  ```

* Создать StatefulSet MinIO и сервис для доступа к нему:

  ```bash
  kubectl apply -f kubernetes-volumes/minio-statefulset.yaml
  kubectl apply -f kubernetes-volumes/minio-headless-service.yaml
  ```

## EX-6.3 Как проверить проект

* Из корня проекта выполнить скрипт `misc/scripts/check_minio.sh`, который создаст Pod с `mc`, создаст `bucket` в который скопирует файл `alpine-release` и выведет листинг этого `bucket`. При успешном завершении, будет выведено:

  ```bash
  misc/scripts/check_minio.sh

  pod/minio-client created
  pod/minio-client condition met
  Bucket created successfully `minio/kubernetes-volumes`.
  /etc/alpine-release:  7 B / 7 B  5.29 KiB/s 0s[2020-01-30 19:18:34 UTC]      7B alpine-release
  ```

## EX-6.4 Как начать пользоваться проектом

* Задание учебное и не предполагает, что им будут "пользоваться".
