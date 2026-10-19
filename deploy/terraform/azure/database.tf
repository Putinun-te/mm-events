# Azure Database for MySQL Flexible Server 8.0, VNet-integrated (no public endpoint).
# require_secure_transport stays ON (the server default).

resource "azurerm_mysql_flexible_server" "main" {
  name                = "mysql-${local.unique}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  version             = "8.0.21"
  sku_name            = var.db_sku

  administrator_login = var.db_username
  # Write-only: sent to Azure, not stored in state. Same value as the Key Vault secret.
  administrator_password_wo         = ephemeral.random_password.db.result
  administrator_password_wo_version = var.secret_version

  delegated_subnet_id = azurerm_subnet.mysql.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  backup_retention_days = 7

  storage {
    size_gb           = var.db_storage_gb
    auto_grow_enabled = true
  }

  lifecycle {
    # Azure picks an availability zone when none is given
    ignore_changes = [zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

resource "azurerm_mysql_flexible_database" "app" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
