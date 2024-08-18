locals {

}

resource "null_resource" "precheck" {
  provisioner "local-exec" {
    command = <<EOT
    # if ! command -v nvm &> /dev/null
    # then
    #     echo "command nvm not found, installing now."
    #     if ! command -v curl &> /dev/null
    #     then
    #         wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    #     else
    #         curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    #     fi
    # fi
    if ! command -v npm &> /dev/null
    then
        echo "Command npm not found, installing now."
        nvm install node
        nvm use node
    fi
    if ! command -v bw &> /dev/null
    then
        echo "Command bw not found, installing now."
        npm install -g --registry https://registry.npmjs.org/ @bitwarden/cli 
    fi
    if ! command -v az &> /dev/null
    then
        echo "Command az not found, installing now."
        pip install azure-cli
    fi
    EOT
  }
}

data "azuread_client_config" "current" {}

resource "azuread_application" "service_principal" {
  display_name = "isonet-casa-terraform-state-storage"
  owners       = [data.azuread_client_config.current.object_id]
  web {
    homepage_url = "https://isonet-casa-terraform-state-storage-sp"
  }
}

// Create the service principle and associate it with the app
resource "azuread_service_principal" "service_principal" {
  owners         = [data.azuread_client_config.current.object_id]
  client_id = azuread_application.service_principal.client_id
}
