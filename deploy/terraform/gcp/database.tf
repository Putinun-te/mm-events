# Cloud SQL for MySQL 8 with a private IP only, TLS required.

resource "google_sql_database_instance" "mysql" {
  name                = var.name
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = var.deletion_protection

  settings {
    edition           = "ENTERPRISE"
    tier              = var.db_tier
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.db_disk_size_gb
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = false
    }

    deletion_protection_enabled = var.deletion_protection
  }

  depends_on = [google_service_networking_connection.private_services]
}

resource "google_sql_database" "app" {
  name      = var.db_name
  instance  = google_sql_database_instance.mysql.name
  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

resource "google_sql_user" "app" {
  name     = var.db_username
  instance = google_sql_database_instance.mysql.name
  host     = "%"

  # Write-only: sent to Cloud SQL, not stored in state. Same value as the secret below.
  password_wo         = ephemeral.random_password.db.result
  password_wo_version = var.secret_version
}
