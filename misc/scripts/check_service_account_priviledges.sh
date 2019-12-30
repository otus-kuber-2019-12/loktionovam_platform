#!/usr/bin/env bash
# set -x
VERB_LIST="create delete deletecollection get list patch update watch"
SCRIPT_NAME=$(basename $0)

function show_help {
cat << EOF

Check privileges for given service account in given namespace

Usage: ${SCRIPT_NAME} -n NAMESPACE -s SERVICE_ACCOUNT

Example: check_service_account_priviledges.sh -n default -s system:serviceaccount:dev:jane

EOF
}

while getopts ":n:s:h" OPTION; do
    case $OPTION in
        n)NAMESPACE="${OPTARG}"
            ;;
        s)SERVICE_ACCOUNT="${OPTARG}"
            ;;
        h) show_help
            exit
            ;;
        *) show_help
            exit
    esac
done

for VERB in $VERB_LIST; do
    echo -n "$SERVICE_ACCOUNT can $VERB in $NAMESPACE: "
    kubectl auth can-i $VERB '*' --as $SERVICE_ACCOUNT -n $NAMESPACE
done
