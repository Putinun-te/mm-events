# Backend: Artifact Registry image -> Cloud Run, reachable only through the load balancer.

resource "google_artifact_registry_repository" "backend" {
  repository_id = var.name
  location      = var.region
  format        = "DOCKER"
  description   = "MM Events backend images"

  cleanup_policies {
    id     = "keep-last-10"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "backend" {
  account_id   = "${var.name}-backend"
  display_name = "MM Events backend (Cloud Run)"
}

resource "google_secret_manager_secret_iam_member" "backend" {
  for_each = {
    db  = google_secret_manager_secret.db_password.id
    jwt = google_secret_manager_secret.jwt.id
  }

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.backend.member
}

locals {
  image    = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.backend.repository_id}/backend:${var.image_tag}"
  jdbc_url = "jdbc:mysql://${google_sql_database_instance.mysql.private_ip_address}:3306/${var.db_name}?sslMode=REQUIRED"
}

resource "google_cloud_run_v2_service" "backend" {
  name                = "${var.name}-backend"
  location            = var.region
  deletion_protection = var.deletion_protection

  # Only the external load balancer may call the service; its run.app URL is closed.
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  # Public API: no IAM check on invocation (the app does its own JWT auth)
  invoker_iam_disabled = true

  template {
    service_account = google_service_account.backend.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = google_compute_network.main.id
        subnetwork = google_compute_subnetwork.run.id
      }
    }

    containers {
      image = local.image

      # Cloud Run sets PORT=8080 itself
      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.backend_cpu
          memory = var.backend_memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.spring_profile
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
        value = local.site_url
      }
      env {
        name = "SPRING_DATASOURCE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.jwt.secret_id
            version = "latest"
          }
        }
      }

      # Spring Boot + Flyway may take ~30-60 s on a cold start
      startup_probe {
        initial_delay_seconds = 10
        period_seconds        = 10
        timeout_seconds       = 5
        failure_threshold     = 18

        http_get {
          path = "/actuator/health"
        }
      }

      liveness_probe {
        period_seconds    = 30
        timeout_seconds   = 5
        failure_threshold = 3

        http_get {
          path = "/actuator/health"
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.backend,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.jwt,
    google_sql_user.app,
  ]
}
