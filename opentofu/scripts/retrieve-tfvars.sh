#!/bin/bash

# Retrieve the terraform.tfvars file from Bitwarden
bw login --apikey
BW_SESSION=$(bw unlock --passwordenv BW_MASTER_PASSWORD --raw)
bw --nointeraction --session ${BW_SESSION} sync

# Retrieve the terraform.tfvars content
TFVARS_CONTENT=$(bw --nointeraction --session ${BW_SESSION} list items | jq -r '.[] | select(.name | startswith("terraform.tfvars")) | .notes')

# Check if the content is empty
if [ -z "$TFVARS_CONTENT" ]; then
    echo "Error: terraform.tfvars not found in Bitwarden."
    exit 1
fi

# Write the content to the file
echo "$TFVARS_CONTENT" > "${OPENTOFU_DIR}/terraform.tfvars"
