#!/usr/bin/env bash
# this script configure minimal env to start ansible bootstrap playbook

SCRIPTS_DIR="$(dirname "$(realpath "${0}")")"
ANSIBLE_DIR=${SCRIPTS_DIR}/../ansible
GENERIC_FUNCTIONS="${SCRIPTS_DIR}"/generic-functions
SCRIPT_NAME=$(basename "${0}")
GCP_SERVICE_ACCOUNT=ansible-$(date +%s)
GCP_ACCOUNT_DIR="${HOME}/.gcloud"
# I can't simply detect a linux distro via lsb_release, because i am use the Linux Mint,
# that doesn't supported by GCP, so use hardcode here
UBUNTU_RELEASE=bionic

if [[ ! -r "${GENERIC_FUNCTIONS}" ]]; then
  logger --tag "${SCRIPT_NAME}" --stderr --id=$$ -p user.err "Can't find ${GENERIC_FUNCTIONS} file. Abort."
  exit 2
fi

# shellcheck source=/dev/null
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

if [ -z "${GCP_PROJECT}" ]; then
  msg_error "GCP_PROJECT variable empty!"
  show_help
  exit
fi

exec_cmd "sudo apt-get update" \
    "Update apt cache"

exec_cmd "sudo apt-get install --yes apache2-utils autoconf curl gcc python-dev virtualenv unzip" \
    "Install prerequisite packages"

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
exec_cmd "sudo dpkg-reconfigure locales" \
    "Configure locales (Virtualenv don't working without configured locales)"

msg_info "Install gcloud"
export CLOUD_SDK_REPO="cloud-sdk-${UBUNTU_RELEASE}"
exec_cmd "echo \"deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main\" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list" \
    "Enable gcloud sdk repository"

exec_cmd "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -" \
    "Download and install gcloud sdk repository key"

exec_cmd "sudo apt-get update" \
    "Update apt cache"

exec_cmd "sudo apt-get install --yes google-cloud-sdk" \
    "Install google-cloud-sdk"

msg_info "Configure gcloud ansible service account"

exec_cmd "gcloud init" \
    "Initialize gcloud"

exec_cmd "gcloud iam service-accounts create ${GCP_SERVICE_ACCOUNT} --display-name ${GCP_SERVICE_ACCOUNT}" \
    "Create ${GCP_SERVICE_ACCOUNT} service account"

exec_cmd "mkdir -p ${GCP_ACCOUNT_DIR}/" \
    "Create directory for gce-service-account"

exec_cmd "mkdir -p ${GCP_ACCOUNT_DIR}/" \
    "Fix permissions for"

exec_cmd "gcloud iam service-accounts keys create ${GCP_ACCOUNT_DIR}/gce-service-account.json --iam-account ${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT}.iam.gserviceaccount.com" \
    "Create gce-service-account.json"

exec_cmd "gcloud projects add-iam-policy-binding ${GCP_PROJECT} --member serviceAccount:${GCP_SERVICE_ACCOUNT}@${GCP_PROJECT}.iam.gserviceaccount.com --role roles/editor" \
		"Bind roles/editor to the ${GCP_SERVICE_ACCOUNT} service account"

exec_cmd "gcloud auth application-default login" \
		"Create Application Default Credentials (ADC)"

exec_cmd "cd ${ANSIBLE_DIR}" \
		"Enter to ${ANSIBLE_DIR} directory"

exec_cmd "virtualenv --system-site-packages -p python3 .venv" \
		"Create virtual environment"

exec_cmd "source .venv/bin/activate" \
		"Source .venv/bin/activate"

exec_cmd "pip install -r requirements.txt" \
		"Install requirements via pip"

msg_info "Continue bootstrap with ansible"
ansible-playbook -K playbooks/bootstrap.yml --extra-vars="gcp_project=$GCP_PROJECT"
