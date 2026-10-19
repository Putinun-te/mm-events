# Workload Identity: Kubernetes service accounts exchange their tokens for Entra ID tokens
# of a user-assigned managed identity through a federated credential.

locals {
  token_audience = "api://AzureADTokenExchange"
}

# --- Backend: read the two Key Vault secrets (used by the External Secrets Operator
#     through the backend's service account) ---------------------------------------------

resource "azurerm_user_assigned_identity" "backend" {
  name                = "id-${var.name}-backend"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_federated_identity_credential" "backend" {
  name                      = "aks-${var.k8s_namespace}-${var.k8s_service_account}"
  user_assigned_identity_id = azurerm_user_assigned_identity.backend.id
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"
  audience                  = [local.token_audience]
}

resource "azurerm_role_assignment" "backend_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
  principal_type       = "ServicePrincipal"
}

# --- ALB Controller (Application Gateway for Containers) ---------------------------------

resource "azurerm_user_assigned_identity" "alb_controller" {
  name                = "id-${var.name}-alb-controller"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Service account created by the alb-controller Helm chart
resource "azurerm_federated_identity_credential" "alb_controller" {
  name                      = "aks-azure-alb-system-alb-controller-sa"
  user_assigned_identity_id = azurerm_user_assigned_identity.alb_controller.id
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject                   = "system:serviceaccount:azure-alb-system:alb-controller-sa"
  audience                  = [local.token_audience]
}

resource "azurerm_role_assignment" "alb_controller" {
  for_each = {
    reader     = { scope = azurerm_kubernetes_cluster.main.node_resource_group_id, role = "Reader" }
    agc_config = { scope = azurerm_application_load_balancer.main.id, role = "AppGw for Containers Configuration Manager" }
    subnet     = { scope = azurerm_subnet.agc.id, role = "Network Contributor" }
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.alb_controller.principal_id
  principal_type       = "ServicePrincipal"
}
