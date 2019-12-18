#!/usr/bin/env bash
# this script configure minimal env to start ansible bootstrap playbook

SCRIPTS_DIR=$(dirname $(realpath "$0"))
ANSIBLE_DIR=${SCRIPTS_DIR}/../ansible
GENERIC_FUNCTIONS="${SCRIPTS_DIR}"/generic-functions
SCRIPT_NAME=$(basename $0)

if [ ! -r "${GENERIC_FUNCTIONS}" ]; then
  logger --tag ${SCRIPT_NAME} --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

source "${GENERIC_FUNCTIONS}"

function show_help {
  echo "Usage: ${SCRIPT_NAME} [-p GCP_PROJECT_NAME]"
}

while getopts ":p:h" OPTION
do
  case $OPTION in
    p)GCP_PROJECT="${OPTARG}"
      ;;
    h) show_help
      exit
      ;;
    *) show_help
      exit
  esac
done

exec_cmd "sudo apt-get update" \
    "Update apt cache"

exec_cmd "sudo apt-get install --yes apache2-utils autoconf curl gcc python-dev virtualenv unzip" \
    "Install prerequisite packages"

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
exec_cmd "sudo dpkg-reconfigure locales" \
    "Configure locales (Virtualenv don't working without configured locales)"

exec_cmd "cd ${ANSIBLE_DIR}" \
		"Enter to ${ANSIBLE_DIR} directory"

exec_cmd "virtualenv .venv" \
		"Create virtual environment"

exec_cmd "source .venv/bin/activate" \
		"Source .venv/bin/activate"

exec_cmd "pip install -r requirements.txt" \
		"Install requirements via pip"

msg_info "Continue bootstrap with ansible"
ansible-playbook -K playbooks/bootstrap.yml --extra-vars="gcp_project=$GCP_PROJECT"
