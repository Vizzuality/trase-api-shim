resource "google_project_service" "iam_service" {
  project            = var.gcp_project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions_api" {
  project            = var.gcp_project_id
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudrun_api" {
  project            = var.gcp_project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild_api" {
  project            = var.gcp_project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project            = var.gcp_project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

locals {
  domain = var.subdomain == "" ? var.domain : "${var.subdomain}.${var.domain}"
}

module "bigquery_credentials" {
  source           = "../secret_value"
  gcp_project_id   = var.gcp_project_id
  region           = var.gcp_region
  key              = "${var.project_name}_bigquery_credentials"
  value            = var.bigquery_credentials
  use_random_value = false
}

locals {
  cloud_function_env = {
    "BIGQUERY_SNAPSHOT" = var.bigquery_snapshot
  }
  cloud_function_secrets = [
    {
      key        = "BIGQUERY_CREDENTIALS"
      project_id = var.gcp_project_id
      secret     = module.bigquery_credentials.secret_name
      version    = module.bigquery_credentials.latest_version
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
  source                = "../load-balancer"
  region                = var.gcp_region
  project               = var.gcp_project_id
  name                  = var.project_name
  domain                = var.domain
  subdomain             = var.subdomain
  dns_managed_zone_name = var.dns_zone_name
  functions_path_prefix = var.functions_path_prefix

  cloud_functions = {
    contexts = {
      name        = module.contexts_cloud_function.function_name
      path_prefix = "contexts"
    },
    columns = {
      name        = module.columns_cloud_function.function_name
      path_prefix = "columns"
    },
    nodes = {
      name        = module.nodes_cloud_function.function_name
      path_prefix = "nodes"
    },
    top-nodes = {
      name        = module.top_nodes_cloud_function.function_name
      path_prefix = "top-nodes"
    }
  }

  depends_on = [google_project_service.compute_api]
}

module "contexts_cloud_function" {
  source                           = "../cloudfunction"
  region                           = var.gcp_region
  cf_service_account               = google_service_account.cf_service_account
  function_name                    = "${var.project_name}-contexts"
  description                      = "Contexts Cloud Function"
  source_dir                       = "${path.root}/../../cloud_functions/contexts"
  runtime                          = "python312"
  entry_point                      = "index"
  runtime_environment_variables    = local.cloud_function_env
  secrets                          = local.cloud_function_secrets
  timeout_seconds                  = var.function_timeout_seconds
  available_memory                 = var.contexts_function_available_memory
  available_cpu                    = var.function_available_cpu
  max_instance_count               = var.function_max_instance_count
  max_instance_request_concurrency = var.function_max_instance_request_concurrency

  depends_on = [google_project_service.cloudrun_api]
}

module "columns_cloud_function" {
  source                           = "../cloudfunction"
  region                           = var.gcp_region
  cf_service_account               = google_service_account.cf_service_account
  function_name                    = "${var.project_name}-columns"
  description                      = "Columns Cloud Function"
  source_dir                       = "${path.root}/../../cloud_functions/columns"
  runtime                          = "python312"
  entry_point                      = "index"
  runtime_environment_variables    = local.cloud_function_env
  secrets                          = local.cloud_function_secrets
  timeout_seconds                  = var.function_timeout_seconds
  available_memory                 = var.function_available_memory
  available_cpu                    = var.function_available_cpu
  max_instance_count               = var.function_max_instance_count
  max_instance_request_concurrency = var.function_max_instance_request_concurrency

  depends_on = [google_project_service.cloudrun_api]
}

module "nodes_cloud_function" {
  source                           = "../cloudfunction"
  region                           = var.gcp_region
  cf_service_account               = google_service_account.cf_service_account
  function_name                    = "${var.project_name}-nodes"
  description                      = "Nodes Cloud Function"
  source_dir                       = "${path.root}/../../cloud_functions/nodes"
  runtime                          = "python312"
  entry_point                      = "index"
  runtime_environment_variables    = local.cloud_function_env
  secrets                          = local.cloud_function_secrets
  timeout_seconds                  = var.function_timeout_seconds
  available_memory                 = var.nodes_function_available_memory
  available_cpu                    = var.function_available_cpu
  max_instance_count               = var.function_max_instance_count
  max_instance_request_concurrency = var.function_max_instance_request_concurrency

  depends_on = [google_project_service.cloudrun_api]
}

module "top_nodes_cloud_function" {
  source                           = "../cloudfunction"
  region                           = var.gcp_region
  cf_service_account               = google_service_account.cf_service_account
  function_name                    = "${var.project_name}-top-nodes"
  description                      = "Top Nodes Cloud Function"
  source_dir                       = "${path.root}/../../cloud_functions/top_nodes"
  runtime                          = "python312"
  entry_point                      = "index"
  runtime_environment_variables    = local.cloud_function_env
  secrets                          = local.cloud_function_secrets
  timeout_seconds                  = var.function_timeout_seconds
  available_memory                 = var.function_available_memory
  available_cpu                    = var.function_available_cpu
  max_instance_count               = var.function_max_instance_count
  max_instance_request_concurrency = var.function_max_instance_request_concurrency

  depends_on = [google_project_service.cloudrun_api]
}
