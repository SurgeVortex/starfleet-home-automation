#!/bin/bash

# Retrieve the terraform.tfvars file from Bitwarden
bw login --apikey
export BW_SESSION=$(bw unlock --passwordenv BW_MASTER_PASSWORD --raw)
bw list items | jq -r '.[] | select(.name | startswith("terraform.tfvars")) | .notes' > "${OPENTOFU_DIR}/terraform.tfvars"

# Set up exit trap to clean up
trap 'rm -f "${OPENTOFU_DIR}/terraform.tfvars"' EXIT
