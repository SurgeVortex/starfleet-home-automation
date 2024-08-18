cd opentofu/prerequisites
PLAN_FILE="${PWD}/.tf-plan"

function cleanup {
  echo "Removing Plan File: ${PLAN_FILE}"
  rm  ${PLAN_FILE}
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
if ! command -v az &> /dev/null
then
    echo "Command az not found, installing now."
    pip install azure-cli
fi

tofu init
if [ "${1}" == "destroy" ]
then
    tofu plan -out=${PLAN_FILE} -destroy
else
    tofu plan -out=${PLAN_FILE}
fi
if [ ${?} -ne 0 ]
then
    exit
fi

if [ "${1}" == "destroy" ]
then
    read -p "Continue with destroy [Yes/no]? " ANSWER
else
    read -p "Continue with apply [Yes/no]? " ANSWER
fi
ANSWER=$(echo ${ANSWER} | tr '[:upper:]' '[:lower:]')
ANSWER=${ANSWER:-yes}

if [ ${ANSWER} == "yes" ]
then
    tofu apply -auto-approve ${PLAN_FILE}
else
    echo "Cancelled Approve"
fi
