# Frontend: Cloud Storage bucket behind a global external Application Load Balancer with
# Cloud CDN. The same load balancer routes the API paths to Cloud Run (serverless NEG),
# so the site and the API share one origin.

resource "google_storage_bucket" "site" {
  name                        = "${var.project_id}-${var.name}-site"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  # Single-page app: unknown paths get index.html (served with status 404, which the
  # browser renders normally).
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
}

# A backend bucket needs publicly readable objects. The site is public anyway.
resource "google_storage_bucket_iam_member" "site_public" {
  bucket = google_storage_bucket.site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_compute_backend_bucket" "site" {
  name        = "${var.name}-site"
  bucket_name = google_storage_bucket.site.name
  enable_cdn  = true

  cdn_policy {
    cache_mode  = "CACHE_ALL_STATIC"
    default_ttl = 3600
    client_ttl  = 3600
    max_ttl     = 86400
  }
}

resource "google_compute_region_network_endpoint_group" "backend" {
  name                  = "${var.name}-backend"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.backend.name
  }
}

resource "google_compute_backend_service" "backend" {
  name                  = "${var.name}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group = google_compute_region_network_endpoint_group.backend.id
  }
}

resource "google_compute_global_address" "lb" {
  name = "${var.name}-lb"

  depends_on = [google_project_service.apis]
}

locals {
  https    = var.domain != ""
  site_url = local.https ? "https://${var.domain}" : "http://${google_compute_global_address.lb.address}"
}

resource "google_compute_url_map" "main" {
  name            = var.name
  default_service = google_compute_backend_bucket.site.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "app"
  }

  path_matcher {
    name            = "app"
    default_service = google_compute_backend_bucket.site.id

    path_rule {
      paths   = ["/api/*", "/actuator/health", "/swagger-ui.html", "/swagger-ui/*", "/v3/api-docs", "/v3/api-docs/*"]
      service = google_compute_backend_service.backend.id
    }
  }
}

# --- HTTP (always) -----------------------------------------------------------------------

# With a domain, port 80 only redirects to HTTPS.
resource "google_compute_url_map" "https_redirect" {
  count = local.https ? 1 : 0
  name  = "${var.name}-https-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "main" {
  name    = "${var.name}-http"
  url_map = local.https ? google_compute_url_map.https_redirect[0].id : google_compute_url_map.main.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name}-http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb.id
  port_range            = "80"
  target                = google_compute_target_http_proxy.main.id
}

# --- HTTPS (only with a domain) ----------------------------------------------------------

resource "google_compute_managed_ssl_certificate" "main" {
  count = local.https ? 1 : 0
  name  = "${var.name}-cert"

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "main" {
  count            = local.https ? 1 : 0
  name             = "${var.name}-https"
  url_map          = google_compute_url_map.main.id
  ssl_certificates = [google_compute_managed_ssl_certificate.main[0].id]
}

resource "google_compute_global_forwarding_rule" "https" {
  count                 = local.https ? 1 : 0
  name                  = "${var.name}-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.main[0].id
}
