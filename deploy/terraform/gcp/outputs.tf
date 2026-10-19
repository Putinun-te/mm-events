output "site_url" {
  description = "Public URL of the site and API (GKE Ingress on the reserved static IP)."
  value       = "http://${google_compute_global_address.ingress.address}"
}

output "ingress_ip" {
  description = "Static IP of the Ingress load balancer. With a domain, point its A record here."
  value       = google_compute_global_address.ingress.address
}

output "cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.main.name
}

output "kubeconfig_command" {
  description = "Writes a kubeconfig entry for the cluster (needs the gke-gcloud-auth-plugin)."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --zone ${var.zone} --project ${var.project_id}"
}

output "image_repository" {
  description = "Push images as <this>/backend:<tag> and <this>/frontend:<tag>."
  value       = local.image_repository
}

output "db_private_ip" {
  description = "Cloud SQL private IP (reachable from the VPC only)."
  value       = google_sql_database_instance.mysql.private_ip_address
}

output "backend_gcp_service_account" {
  description = "Google service account mapped to the backend's Kubernetes service account."
  value       = google_service_account.backend.email
}

# Values for deploy/helm/mm-events, together with values-gcp.yaml. Contains no secret
# values, only names and addresses:
#   terraform output -raw helm_values > mm-events-values.yaml
output "helm_values" {
  description = "Cloud-specific values for the Helm chart (no secrets)."
  value = yamlencode({
    publicUrl = "http://${google_compute_global_address.ingress.address}"
    backend = {
      image = { repository = "${local.image_repository}/backend" }
      datasource = {
        host     = google_sql_database_instance.mysql.private_ip_address
        database = var.db_name
        username = var.db_username
      }
      serviceAccount = {
        name        = var.k8s_service_account
        annotations = { "iam.gke.io/gcp-service-account" = google_service_account.backend.email }
      }
    }
    frontend = {
      image = { repository = "${local.image_repository}/frontend" }
    }
    ingress = {
      annotations = {
        "kubernetes.io/ingress.class"                 = "gce"
        "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.ingress.name
      }
    }
    secrets = {
      externalSecrets = {
        provider = {
          gcpsm = {
            projectID = var.project_id
            auth = {
              workloadIdentity = {
                clusterLocation   = var.zone
                clusterName       = google_container_cluster.main.name
                clusterProjectID  = var.project_id
                serviceAccountRef = { name = var.k8s_service_account }
              }
            }
          }
        }
        dbPassword = { key = google_secret_manager_secret.db_password.secret_id }
        jwtSecret  = { key = google_secret_manager_secret.jwt.secret_id }
      }
    }
  })
}
