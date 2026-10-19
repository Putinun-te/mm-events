resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "sts.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# VPC-native subnet for GKE: nodes on the primary range, pods and Services on secondary
# ranges. Private Google Access lets the private nodes reach Artifact Registry and the
# Google APIs without public IPs.

resource "google_compute_network" "main" {
  name                    = var.name
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "gke" {
  name                     = "${var.name}-gke"
  network                  = google_compute_network.main.id
  region                   = var.region
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# Outbound internet for the private nodes (images from ghcr.io, registry.k8s.io, ...)
resource "google_compute_router" "main" {
  name    = var.name
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = var.name
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Private Service Access: Cloud SQL gets a private IP inside this VPC
resource "google_compute_global_address" "private_services" {
  name          = "${var.name}-private-services"
  network       = google_compute_network.main.id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
}

resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]

  # Google removes the peering itself once Cloud SQL is gone; deleting it from Terraform
  # right after the instance usually fails.
  deletion_policy = "ABANDON"
}

# Static IP for the GKE Ingress, so the site's URL is known before the chart is installed
resource "google_compute_global_address" "ingress" {
  name = "${var.name}-ingress"

  depends_on = [google_project_service.apis]
}
