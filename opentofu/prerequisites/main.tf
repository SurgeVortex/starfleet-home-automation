locals {}

# data "azuread_client_config" "current" {}

# resource "azuread_application" "service_principal" {
#   display_name = "isonet-casa-terraform-state-storage"
#   owners       = [data.azuread_client_config.current.object_id]
#   web {
#     homepage_url = "https://isonet-casa-terraform-state-storage-sp"
#   }
# }

# // Create the service principle and associate it with the app
# resource "azuread_service_principal" "service_principal" {
#   owners    = [data.azuread_client_config.current.object_id]
#   client_id = azuread_application.service_principal.client_id
# }

# resource "azuread_service_principal_password" "example" {
#   service_principal_id = azuread_service_principal.service_principal.client_id
# }

resource "bitwarden_folder" "starfleet-home-automation" {
  name = var.bitwarden-folder
}
