#!/usr/bin/env bash
set -euo pipefail

# This script based on
# https://www.vaultproject.io/docs/platform/k8s/helm/examples/standalone-tls

SCRIPTS_DIR=$(dirname "$(readlink --canonicalize-existing "$0")")

# shellcheck source=/vault_cert.conf
source "${SCRIPTS_DIR}/vault_cert.conf"

echo "Create a key for Kubernetes to sign."
openssl genrsa -out "${TMPDIR}/vault.key" 2048

echo "Create an openssl configuration"
cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF

echo "Create a CSR"
openssl req -new    -key "${TMPDIR}/vault.key" \
                    -subj "/CN=${SERVICE}.${NAMESPACE}.svc" \
                    -out "${TMPDIR}/server.csr" \
                    -config "${TMPDIR}/csr.conf"

echo "Create the certificate"

cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(base64 < "${TMPDIR}/server.csr" | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl create -f "${TMPDIR}/csr.yaml"


kubectl certificate approve "${CSR_NAME}"
