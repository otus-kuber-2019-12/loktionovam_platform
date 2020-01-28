#!/usr/bin/env bash

WEB_ADDR=$(kubectl get svc -n ingress-nginx -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')
if curl -H 'Host: web' -H 'Canary: always' "http://${WEB_ADDR}/web/index.html" | grep "export HOSTNAME='web-v2"; then
    echo "'Web' application (v2, canary) is OK via nginx ingress"
else
    echo "'Web' application access error via nginx ingress"
fi
