#!/usr/bin/env bash
set -euo pipefail

TEST_CHART_NAME=check_chartmuseum
CHARTMUSEUM_URL="https://chartmuseum.35.240.65.117.nip.io"
CHARTMUSEUM_API_URL="${CHARTMUSEUM_URL}/api"

# Don't use helm-push plugin. Only curl, only hardcore!
pushd "$(mktemp -d)"
    curl --request DELETE ${CHARTMUSEUM_API_URL}/charts/${TEST_CHART_NAME}/0.1.0
    echo "Create test helm package ${TEST_CHART_NAME}"
    helm create "${TEST_CHART_NAME}"
    cd "${TEST_CHART_NAME}"
    helm package .
    echo "Upload test helm package ${TEST_CHART_NAME}-0.1.0.tgz to the ${CHARTMUSEUM_URL}"
    if ! curl --fail --data-binary "@${TEST_CHART_NAME}-0.1.0.tgz" "${CHARTMUSEUM_API_URL}/charts"; then
        echo "Something going wrong while upload test chart"
        exit 1
    fi

    echo "Get information about uploaded chart"
    curl "https://chartmuseum.35.240.65.117.nip.io/api/charts/${TEST_CHART_NAME}" 2> /dev/null | jq .

    echo "Try to add chartmuseum repo to helm and install test chart"
    helm repo add chartmuseum "${CHARTMUSEUM_URL}"
    helm install --dry-run 0.1.0 chartmuseum/${TEST_CHART_NAME}

    echo "Remove ${TEST_CHART_NAME} from ${CHARTMUSEUM_URL}"
    curl --request DELETE ${CHARTMUSEUM_API_URL}/charts/${TEST_CHART_NAME}/0.1.0 2>/dev/null | jq .
    echo "Remove chartmuseum repo from helm repositories list"
    helm repo remove chartmuseum

popd
