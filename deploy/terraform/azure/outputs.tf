output "site_url" {
  description = "Public URL of the site and API (Application Gateway for Containers frontend)."
  value       = "http://${azurerm_application_load_balancer_frontend.main.fully_qualified_domain_name}"
}

output "resource_group" {
  description = "Resource group holding everything."
  value       = azurerm_resource_group.main.name
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.main.name
}

output "kubeconfig_command" {
  description = "Writes a kubeconfig entry for the cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "acr_name" {
  description = "ACR name, for 'az acr login --name'."
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Push images as <this>/backend:<tag> and <this>/frontend:<tag>."
  value       = azurerm_container_registry.main.login_server
}

output "alb_controller_client_id" {
  description = "Client ID of the ALB Controller's managed identity (Helm value albController.podIdentity.clientID)."
  value       = azurerm_user_assigned_identity.alb_controller.client_id
}

output "key_vault" {
  description = "Key Vault holding db-password and jwt-secret."
  value       = azurerm_key_vault.main.name
}

output "mysql_server_fqdn" {
  description = "MySQL Flexible Server host (private DNS, VNet only)."
  value       = azurerm_mysql_flexible_server.main.fqdn
}

# Values for deploy/helm/mm-events, together with values-azure.yaml. Contains no secret
# values, only names, IDs and hostnames:
#   terraform output -raw helm_values > mm-events-values.yaml
output "helm_values" {
  description = "Cloud-specific values for the Helm chart (no secrets)."
  value = yamlencode({
    publicUrl = "http://${azurerm_application_load_balancer_frontend.main.fully_qualified_domain_name}"
    backend = {
      image = { repository = "${azurerm_container_registry.main.login_server}/backend" }
      datasource = {
        host     = azurerm_mysql_flexible_server.main.fqdn
        database = var.db_name
        username = var.db_username
      }
      serviceAccount = {
        name        = var.k8s_service_account
        annotations = { "azure.workload.identity/client-id" = azurerm_user_assigned_identity.backend.client_id }
        labels      = { "azure.workload.identity/use" = "true" }
      }
    }
    frontend = {
      image = { repository = "${azurerm_container_registry.main.login_server}/frontend" }
    }
    ingress = {
      annotations = {
        "alb.networking.azure.io/alb-id"       = azurerm_application_load_balancer.main.id
        "alb.networking.azure.io/alb-frontend" = azurerm_application_load_balancer_frontend.main.name
      }
    }
    secrets = {
      externalSecrets = {
        provider = {
          azurekv = {
            authType          = "WorkloadIdentity"
            vaultUrl          = azurerm_key_vault.main.vault_uri
            serviceAccountRef = { name = var.k8s_service_account }
          }
        }
        dbPassword = { key = azurerm_key_vault_secret.db_password.name }
        jwtSecret  = { key = azurerm_key_vault_secret.jwt.name }
      }
    }
  })
}
