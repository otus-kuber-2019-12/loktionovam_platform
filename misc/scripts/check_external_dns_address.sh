#!/usr/bin/env bash

EXTERNAL_DNS=$(kubectl get svc -n kube-system dns-svc-lb-udp -o jsonpath='{.status.loadBalancer.ingress[*].ip}')

if host web-svc-cip.default.svc.cluster.local "${EXTERNAL_DNS}" | grep 'web-svc-cip.default.svc.cluster.local has address'; then
    echo "External CoreDNS is OK"
else
    echo "External CoreDNS is error"
fi

