#!/bin/bash
# Get the name of the script
SCRIPT_NAME=$(basename "$0")

# Check if the lock file exists
if [ -f "/tmp/${SCRIPT_NAME}.lock" ]; then
    echo "Script is already running. Exiting..."
    exit 1
fi

# Create the lock file
touch "/tmp/${SCRIPT_NAME}.lock"

PARENT_DIR=${PWD}
PRE_REQ_DIR="${PARENT_DIR}/opentofu/prerequisites"
PLAN_FILE="${PRE_REQ_DIR}/.tf-plan"
AZURE_TENANT_ID=${1}
DESTROY=${2}

function cleanup {
  echo "Removing Plan File: ${PLAN_FILE}"
  rm -f ${PLAN_FILE}
  echo "Removing Lock File: /tmp/${SCRIPT_NAME}.lock"
  rm -f "/tmp/${SCRIPT_NAME}.lock"
}

trap 'cleanup' EXIT

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
    npm install -g --save --registry https://registry.npmjs.org/ @bitwarden/cli 
fi
if ! command -v az &> /dev/null
then
    echo "Command az not found, installing now."
    pip install azure-cli
fi

if [ $(az account list | grep -c "${AZURE_TENANT_ID}") -eq 0 ]
then
    az login --allow-no-subscriptions --tenant "${AZURE_TENANT_ID}" --use-device-code
fi

cd "${PRE_REQ_DIR}"

tofu init -upgrade
TYPE="apply"
if [ "$(echo ${DESTROY} | tr '[:upper:]' '[:lower:]')" == "destroy" ]
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

read -p "Continue with ${TYPE} [Yes/no]? " ANSWER
ANSWER=$(echo ${ANSWER} | tr '[:upper:]' '[:lower:]')
ANSWER=${ANSWER:-yes}

if [ ${ANSWER} == "yes" ]
then
    tofu apply -auto-approve ${PLAN_FILE}
else
    echo "Cancelled Approve"
fi
