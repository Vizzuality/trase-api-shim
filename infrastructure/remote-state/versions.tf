terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.14"
    }
  }
  required_version = "1.7.1"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
