terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.14"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.14"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
  required_version = "1.7.1"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
