data "azurerm_client_config" "current" {}

# ACR, Key Vault and MySQL names are global across Azure
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  compact_name = replace(var.name, "-", "")
  unique       = "${local.compact_name}${random_string.suffix.result}"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name}"
  location = var.location

  tags = {
    project    = var.name
    managed-by = "terraform"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
}

# --- Network: AKS, Application Gateway for Containers and MySQL share a VNet ------------

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
}

# AKS nodes and pods (Azure CNI: pods take IPs from this subnet)
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 6, 0)]
}

# Application Gateway for Containers needs its own delegated subnet (/24 or larger)
resource "azurerm_subnet" "agc" {
  name                 = "snet-agc"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 5)]

  delegation {
    name = "agc"
    service_delegation {
      name    = "Microsoft.ServiceNetworking/trafficControllers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "mysql" {
  name                 = "snet-mysql"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 4)]

  delegation {
    name = "mysql-flexible"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.name}.private.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                = "mysql"
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id
  virtual_network_id  = azurerm_virtual_network.main.id
}
