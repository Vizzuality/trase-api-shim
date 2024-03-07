terraform {
  backend "gcs" {
    // TF does not allow vars here. Use the value from var.bucket_name from the remote-state project
    bucket = "trase-mongabay-shim-tf-state"
    // TF does not allow vars here. Use the value from var.tf_state_prefix
    prefix = "state"
  }
}

module "production" {
  source                                    = "./modules/env"
  gcp_project_id                            = var.gcp_project_id
  gcp_region                                = var.gcp_region
  github_org                                = var.github_org
  github_project                            = var.github_project
  github_branch                             = "main"
  project_name                              = var.production_project_name
  # dns_zone_name                             = module.dns.dns_zone_name
  # domain                                    = var.domain
  # subdomain                                 = var.production_subdomain
  functions_path_prefix                     = "api/v3"
  function_timeout_seconds                  = 600
  function_max_instance_count               = 1
  function_max_instance_request_concurrency = 1
  function_available_memory                 = "128Mi"
  contexts_function_available_memory        = "128Mi"
  nodes_function_available_memory           = "256Mi"
  function_available_cpu                    = null
  environment                               = "production"
  bigquery_credentials                      = file("${path.root}/../../cloud_functions/bigquery_credentials.json")
  bigquery_snapshot                         = var.bigquery_snapshot
}

# module "dns" {
#   source = "./modules/dns"
#   domain = var.domain
#   name   = var.gcp_project_id
# }
