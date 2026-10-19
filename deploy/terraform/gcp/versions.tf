terraform {
  # 1.11+ for write-only arguments, which keep the passwords out of the state file
  required_version = ">= 1.11"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Local state by default. For anything shared, use an encrypted remote backend, e.g.:
  # backend "gcs" {
  #   bucket = "my-terraform-state"
  #   prefix = "mm-events/gcp"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = {
    project    = var.name
    managed-by = "terraform"
  }
}
