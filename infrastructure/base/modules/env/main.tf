resource "google_project_service" "iam_service" {
  project            = var.gcp_project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "cloud_functions_api" {
  project            = var.gcp_project_id
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "cloudrun_api" {
  project            = var.gcp_project_id
  service            = "run.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "cloudbuild_api" {
  project            = var.gcp_project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "compute_api" {
  project            = var.gcp_project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = true
}

locals {
  domain = var.subdomain == "" ? var.domain : "${var.subdomain}.${var.domain}"
}

module "big_query_credentials" {
  source           = "../secret_value"
  gcp_project_id   = var.gcp_project_id
  region           = var.gcp_region
  key              = "${var.project_name}_big_query_credentials"
  value            = var.big_query_credentials
  use_random_value = false
}

locals {
  contexts_cf_lb_url = "https://${local.domain}/${var.functions_path_prefix}/${var.contexts_function_path_prefix}/"

  cloud_function_env = {

  }
  cloud_function_secrets = [
    {
      key        = "BIG_QUERY_CREDENTIALS"
      project_id = var.gcp_project_id
      secret     = module.big_query_credentials.secret_name
      version    = module.big_query_credentials.latest_version
    }
  ]
}

locals {
  gcp_sa_key       = "${upper(var.environment)}_GCP_SA_KEY"
  project_name     = "${upper(var.environment)}_PROJECT_NAME"
  contexts_cf_name = "${upper(var.environment)}_CONTEXTS_CF_NAME"
}

module "github_values" {
  source    = "../github_values"
  repo_name = var.github_project
  secret_map = {
    GCP_PROJECT_ID           = var.gcp_project_id
    GCP_REGION               = var.gcp_region
    (local.gcp_sa_key)       = base64decode(google_service_account_key.deploy_service_account_key.private_key)
    (local.project_name)     = var.project_name
    (local.contexts_cf_name) = module.contexts_cloud_function.function_name
  project = var.gcp_project_id }
}

#
# Cloud functions service account
#
resource "google_service_account" "cf_service_account" {
  account_id   = "${var.project_name}-cf-sa"
  display_name = "${var.project_name} Cloud Functions Service Account"
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  count = length(local.cloud_function_secrets)

  secret_id = local.cloud_function_secrets[count.index]["secret"]
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cf_service_account.email}"

  depends_on = [google_service_account.cf_service_account]
}

# Deploy service account

resource "google_service_account" "deploy_service_account" {
  account_id   = "${var.project_name}-deploy-sa"
  display_name = "${var.project_name} Deploy Service Account"
}

resource "google_service_account_key" "deploy_service_account_key" {
  service_account_id = google_service_account.deploy_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "deploy_service_account_roles" {
  count = length(var.roles)

  project = var.gcp_project_id
  role    = var.roles[count.index]
  member  = "serviceAccount:${google_service_account.deploy_service_account.email}"
}

variable "roles" {
  description = "List of roles to grant to the Cloud Run Deploy Service Account"
  type        = list(string)
  default = [
    # "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    # "roles/run.developer",
    "roles/cloudfunctions.developer"
  ]
}

module "load_balancer" {
  source                        = "../load-balancer"
  region                        = var.gcp_region
  project                       = var.gcp_project_id
  name                          = var.project_name
  contexts_function_name        = module.contexts_cloud_function.function_name
  domain                        = var.domain
  subdomain                     = var.subdomain
  dns_managed_zone_name         = var.dns_zone_name
  functions_path_prefix         = var.functions_path_prefix
  contexts_function_path_prefix = var.contexts_function_path_prefix

  depends_on = [google_project_service.compute_api]
}

module "contexts_cloud_function" {
  source                           = "../cloudfunction"
  region                           = var.gcp_region
  cf_service_account               = google_service_account.cf_service_account
  function_name                    = "${var.project_name}-contexts"
  description                      = "Contexts Cloud Function"
  source_dir                       = "${path.root}/../../cloud_functions/contexts"
  runtime                          = "ruby32"
  entry_point                      = "index"
  runtime_environment_variables    = local.cloud_function_env
  secrets                          = local.cloud_function_secrets
  timeout_seconds                  = var.contexts_function_timeout_seconds
  available_memory                 = var.contexts_function_available_memory
  available_cpu                    = var.contexts_function_available_cpu
  max_instance_count               = var.contexts_function_max_instance_count
  max_instance_request_concurrency = var.contexts_function_max_instance_request_concurrency

  depends_on = [google_project_service.cloudrun_api]
}
