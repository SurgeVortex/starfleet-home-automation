#!/bin/bash

# Retrieve the terraform.tfvars file from Bitwarden
bw login --apikey
BW_SESSION=$(bw unlock --passwordenv BW_MASTER_PASSWORD --raw)
bw --nointeraction --session sync
bw --nointeraction --session ${BW_SESSION} list items | jq -r '.[] | select(.name | startswith("terraform.tfvars")) | .notes' > "${OPENTOFU_DIR}/terraform.tfvars"
