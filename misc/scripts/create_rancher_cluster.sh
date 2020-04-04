#!/usr/bin/env bash
set -euo pipefail

git clone https://github.com/rancher/quickstart
cd quickstart/vagrant

cp kubernetes-logging/audit/rancher/config.yaml quickstart/vagrant

vagrant up

wget "https://github.com/rancher/cli/releases/download/v2.4.0/rancher-linux-amd64-v2.4.0.tar.gz"
tar -xvzf rancher-linux-amd64-v2.4.0.tar.gz
sudo cp ./rancher-v2.4.0/rancher /usr/local/bin/

echo "You need to apply 'kubernetes-logging/audit/rancher/k8s-logging.yaml' to enable audit logs"
echo "Login to racher via: rancher login https://172.22.101.101 --token <token from web ui>"
