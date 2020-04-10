#!/usr/bin/env bash
set -euo pipefail

# Second part https://www.vaultproject.io/docs/platform/k8s/helm/examples/standalone-tls

SCRIPTS_DIR=$(dirname "$(readlink --canonicalize-existing "$0")")

# shellcheck source=/vault_cert.conf
source "${SCRIPTS_DIR}/vault_cert.conf"

echo "Retrieve the certificate from k8s"
serverCert=$(kubectl get csr "${CSR_NAME}" -o jsonpath='{.status.certificate}')


echo "Write the certificate out to the ${TMPDIR}/vault.crt"
echo "${serverCert}" | openssl base64 -d -A -out "${TMPDIR}/vault.crt"

echo "Save Kubernetes CA to the ${TMPDIR}/vault.ca"
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > "${TMPDIR}/vault.ca"

echo "Store the key, cert, and Kubernetes CA into Kubernetes secrets."
kubectl create secret generic "${SECRET_NAME}" \
        --namespace "${NAMESPACE}" \
        --from-file=vault.key="${TMPDIR}/vault.key" \
        --from-file=vault.crt="${TMPDIR}/vault.crt" \
        --from-file=vault.ca="${TMPDIR}/vault.ca"
