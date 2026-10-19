output "frontend_url" {
  description = "Public URL of the site (load balancer)."
  value       = local.site_url
}

output "api_base_url" {
  description = "Base URL of the API, used as NUXT_PUBLIC_BACKEND_BASE_URL. Same origin as the site; the app calls <this>/api/..."
  value       = local.site_url
}

output "health_url" {
  description = "Backend health check through the load balancer."
  value       = "${local.site_url}/actuator/health"
}

output "load_balancer_ip" {
  description = "IP address of the load balancer. With a domain, point its A record here."
  value       = google_compute_global_address.lb.address
}

output "image_repository" {
  description = "Push the backend image as <this>/backend:<tag>."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.backend.repository_id}"
}

output "site_bucket" {
  description = "Cloud Storage bucket for the static frontend files."
  value       = google_storage_bucket.site.name
}

output "cloud_run_service" {
  description = "Cloud Run service name."
  value       = google_cloud_run_v2_service.backend.name
}

output "db_instance" {
  description = "Cloud SQL instance name (private IP only)."
  value       = google_sql_database_instance.mysql.name
}
