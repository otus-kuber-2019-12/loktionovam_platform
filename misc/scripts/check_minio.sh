#!/usr/bin/env bash

# Create minio client pod and check minio server

minio() {
    eval "kubectl exec -ti minio-client -- mc ${1}"
}

KUBECONFIG="$(kind get kubeconfig-path)"
export KUBECONFIG

kubectl apply --force -f kubernetes-volumes/minio-client.yaml
kubectl wait --for=condition=Ready pod/minio-client

minio "mb --ignore-existing minio/kubernetes-volumes"
minio "cp /etc/alpine-release minio/kubernetes-volumes"
minio "ls minio/kubernetes-volumes/alpine-release"
