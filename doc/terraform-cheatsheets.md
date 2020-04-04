# Шпаргалка по terraform

* Доступные версии k8s мастер серверов

```bash
gcloud container get-server-config --zone europe-west1-b
```

* Импортировать terraform state из remote bucket

```bash
terraform import google_storage_bucket.storage-bucket kubernetes-tf-state-bucket-20190202001
```
