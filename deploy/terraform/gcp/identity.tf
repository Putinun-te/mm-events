# Workload Identity: the backend's Kubernetes service account acts as a Google service
# account that may read the two secrets. The External Secrets Operator uses it to copy them
# into a Kubernetes Secret.

resource "google_service_account" "backend" {
  account_id   = "${var.name}-backend"
  display_name = "MM Events backend (GKE Workload Identity)"
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

resource "google_service_account_iam_member" "backend_workload_identity" {
  service_account_id = google_service_account.backend.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"

  # The workload pool exists once the cluster does
  depends_on = [google_container_cluster.main]
}
