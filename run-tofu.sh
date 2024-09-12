#!/bin/bash
# Get the name of the script
SCRIPT_NAME=$(basename "$0")

# Load environment variables from .profile
source ~/.profile

# Check if the lock file exists
if [ -f "/tmp/${SCRIPT_NAME}.lock" ]; then
    echo "Script is already running. Exiting..."
    exit 1
fi

# Create the lock file
touch "/tmp/${SCRIPT_NAME}.lock"

PARENT_DIR=$(dirname "$(readlink -f "$0")")
OPENTOFU_DIR="${PARENT_DIR}/opentofu"
PLAN_FILE="${OPENTOFU_DIR}/.tf-plan"
BITWARDEN_DIR="${OPENTOFU_DIR}/.bitwarden"

function cleanup {
  echo "Removing Plan File: ${PLAN_FILE}"
  rm  ${PLAN_FILE}
  echo "Removing Lock File: /tmp/${SCRIPT_NAME}.lock"
  rm "/tmp/${SCRIPT_NAME}.lock"
  echo "Removing tfvars file: ${OPENTOFU_DIR}/terraform.tfvars"
  rm -f "${OPENTOFU_DIR}/terraform.tfvars"
#   echo "Removing Bitwarden Directory: ${BITWARDEN_DIR}"
#   rm -rf ${BITWARDEN_DIR}
}

trap cleanup EXIT

# pre-requisites
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
if ! command -v nvm &> /dev/null
then
    echo "command nvm not found, installing now."
    if ! command -v curl &> /dev/null
    then
        wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi
if ! command -v bw &> /dev/null
then
    echo "Command bw not found, installing now."
    nvm install --lts
    nvm use --lts
    npm install -g --registry https://registry.npmjs.org/ @bitwarden/cli 
fi

# # Check if the tfvars file exists
# if [ -f "${OPENTOFU_DIR}/terraform.tfvars" ]; then
#     echo "tfvars file already exists. Skipping..."
# else
    source "${OPENTOFU_DIR}/scripts/retrieve-tfvars.sh"
# fi

if [ $(az account list | grep -c "${AZURE_TENANT_ID}") -eq 0 ]
then
    az login --allow-no-subscriptions --tenant "${AZURE_TENANT_ID}" --use-device-code
fi

cd "${OPENTOFU_DIR}"

tofu init -upgrade
TYPE="apply"
if [ "$(echo ${1} | tr '[:upper:]' '[:lower:]')" == "destroy" ]
then
    TYPE="destroy"
    tofu plan -out=${PLAN_FILE} -destroy
else
    tofu plan -out=${PLAN_FILE}
fi
if [ ${?} -ne 0 ]
then
    exit
fi

if [ -n "$1" ]; then
    if [ "$1" == "destroy" ]; then
        TYPE="destroy"
        read -p "Continue with ${TYPE} [Yes/no]? " ANSWER
    elif [ "$1" == "auto-approve" ]; then
        ANSWER="yes"
    fi
else
    read -p "Continue with ${TYPE} [Yes/no]? " ANSWER
fi

ANSWER=$(echo ${ANSWER} | tr '[:upper:]' '[:lower:]')
ANSWER=${ANSWER:-yes}

if [ ${ANSWER} == "yes" ]
then
    tofu apply -auto-approve ${PLAN_FILE}
else
    echo "Cancelled Approve"
fi
