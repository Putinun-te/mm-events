# AKS (Free tier control plane) with Azure CNI in the VNet, the OIDC issuer and Workload
# Identity, an autoscaled system node pool and Container Insights logs to Log Analytics.

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Entra ID authentication only would need an admin group; local accounts stay on for a demo
  role_based_access_control_enabled = true

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    vnet_subnet_id              = azurerm_subnet.aks.id
    auto_scaling_enabled        = true
    node_count                  = var.node_count
    min_count                   = var.node_min_count
    max_count                   = var.node_max_count
    max_pods                    = 50
    os_disk_size_gb             = 30
    temporary_name_for_rotation = "systemtmp"

    upgrade_settings {
      max_surge = "1"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Node auto-provisioning (Karpenter) off: the autoscaled pool above is enough here
  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = cidrhost(var.service_cidr, 10)
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.main.id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle {
    # The cluster autoscaler changes the size
    ignore_changes = [default_node_pool[0].node_count]
  }
}

# The cluster's own identity manages load balancer rules and NICs in the VNet subnet
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
