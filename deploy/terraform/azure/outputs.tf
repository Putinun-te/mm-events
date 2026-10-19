output "frontend_url" {
  description = "Public URL of the site (Static Web App)."
  value       = "https://${azurerm_static_web_app.site.default_host_name}"
}

output "api_base_url" {
  description = "Base URL of the API, used as NUXT_PUBLIC_BACKEND_BASE_URL. The app calls <this>/api/..."
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "health_url" {
  description = "Backend health check."
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}/actuator/health"
}

output "resource_group" {
  description = "Resource group holding everything."
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "Push the backend image as <this>/backend:<tag>."
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "ACR name, for 'az acr login --name'."
  value       = azurerm_container_registry.main.name
}

output "container_app" {
  description = "Container App name."
  value       = azurerm_container_app.backend.name
}

output "key_vault" {
  description = "Key Vault holding db-password and jwt-secret."
  value       = azurerm_key_vault.main.name
}

output "mysql_server" {
  description = "MySQL Flexible Server name (VNet only)."
  value       = azurerm_mysql_flexible_server.main.name
}

output "static_web_app_deployment_token" {
  description = "Token for 'swa deploy'. Read it with 'terraform output -raw static_web_app_deployment_token'."
  value       = azurerm_static_web_app.site.api_key
  sensitive   = true
}
