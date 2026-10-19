# Backend: ACR image -> Azure Container Apps (Consumption), pulling the image and reading
# the Key Vault secrets with a user-assigned managed identity.

resource "azurerm_container_registry" "main" {
  name                = "acr${local.unique}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_user_assigned_identity" "backend" {
  name                = "id-${var.name}-backend"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "backend_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "backend_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.name}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.apps.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

locals {
  frontend_origin = "https://${azurerm_static_web_app.site.default_host_name}"
  jdbc_url        = "jdbc:mysql://${azurerm_mysql_flexible_server.main.fqdn}:3306/${var.db_name}?sslMode=REQUIRED"
}

resource "azurerm_container_app" "backend" {
  name                         = "ca-${var.name}-backend"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.backend.id
  }

  # References to Key Vault; Container Apps resolves the latest version at revision start
  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.db_password.versionless_id
    identity            = azurerm_user_assigned_identity.backend.id
  }

  secret {
    name                = "jwt-secret"
    key_vault_secret_id = azurerm_key_vault_secret.jwt.versionless_id
    identity            = azurerm_user_assigned_identity.backend.id
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "backend"
      image  = "${azurerm_container_registry.main.login_server}/backend:${var.image_tag}"
      cpu    = var.backend_cpu
      memory = var.backend_memory

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.spring_profile
      }
      env {
        name  = "PORT"
        value = "8080"
      }
      env {
        name  = "SPRING_DATASOURCE_URL"
        value = local.jdbc_url
      }
      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.db_username
      }
      env {
        name  = "APP_CORS_ALLOWED_ORIGINS"
        value = local.frontend_origin
      }
      env {
        name        = "SPRING_DATASOURCE_PASSWORD"
        secret_name = "db-password"
      }
      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }

      # Spring Boot + Flyway may take ~30-60 s on a cold start
      startup_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/actuator/health"
        initial_delay           = 10
        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 18
      }

      liveness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/actuator/health"
        interval_seconds        = 30
        timeout                 = 5
        failure_count_threshold = 3
      }
    }
  }

  depends_on = [
    time_sleep.rbac,
    azurerm_mysql_flexible_database.app,
  ]
}
