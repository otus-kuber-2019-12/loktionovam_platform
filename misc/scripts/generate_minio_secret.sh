#!/usr/bin/env bash

MINIO_ACCESS_KEY="${1}"
MINIO_SECRET_KEY="${2}"

kubectl create \
    secret generic minio-secret \
    --dry-run=true \
    --from-literal=minio_access_key="${MINIO_ACCESS_KEY}" \
    --from-literal=minio_secret_key="${MINIO_SECRET_KEY}" \
    --output=yaml
