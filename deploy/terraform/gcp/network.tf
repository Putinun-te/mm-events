resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# VPC used only for the private path Cloud Run -> Cloud SQL. Cloud SQL gets a private IP
# through Private Service Access; Cloud Run reaches it with Direct VPC egress (no connector).

resource "google_compute_network" "main" {
  name                    = var.name
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "run" {
  name                     = "${var.name}-run"
  network                  = google_compute_network.main.id
  region                   = var.region
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

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
