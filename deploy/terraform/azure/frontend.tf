# Frontend: Azure Static Web Apps (Free tier). Global, HTTPS on *.azurestaticapps.net, and
# client-side routes fall back to index.html through staticwebapp.config.json.
# Files are uploaded with the SWA CLI and the deployment token (see README).

resource "azurerm_static_web_app" "site" {
  name                = "swa-${var.name}"
  location            = var.static_web_app_location
  resource_group_name = azurerm_resource_group.main.name
  sku_tier            = "Free"
  sku_size            = "Free"
}
