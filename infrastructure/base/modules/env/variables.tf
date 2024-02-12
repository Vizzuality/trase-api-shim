variable "github_org" {
  type        = string
  description = "Github organization"
}

variable "github_project" {
  type        = string
  description = "Github project name"
}

variable "github_branch" {
  type        = string
  description = "Github project branch"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

# define GCP region
variable "gcp_region" {
  type        = string
  description = "GCP region"
}

# define GCP project id
variable "gcp_project_id" {
  type        = string
  description = "GCP project id"
}

variable "tf_state_prefix" {
  type        = string
  default     = "state"
  description = "The prefix for the TF state in the Google Storage Bucket"
}

variable "dns_zone_name" {
  type        = string
  description = "Name for the GCP DNS Zone"
}

variable "domain" {
  type        = string
  description = "Base domain for the DNS zone"
}

variable "subdomain" {
  type        = string
  default     = ""
  description = "If set, it will be prepended to the domain to form a subdomain."
}

variable "cors_origin" {
  type        = string
  description = "Origin for CORS config"
  default     = "*"
}

variable "environment" {
  type        = string
  description = "staging | production"
}

variable "functions_path_prefix" {
  type        = string
  description = "Path prefix for the functions services"
}

variable "function_timeout_seconds" {
  type        = number
  default     = 180
  description = "Timeout for a cloud function"
}

variable "function_available_memory" {
  type        = string
  default     = "128Mi"
  description = "Available memory for a cloud function"
}

variable "function_available_cpu" {
  type        = number
  nullable    = true
  description = "Available cpu for a cloud function"
}

variable "function_max_instance_count" {
  type        = number
  default     = 1
  description = "Max instance count for a cloud function"
}

variable "function_max_instance_request_concurrency" {
  type        = number
  default     = 1
  description = "Max instance request concurrency for a cloud function"
}

variable "big_query_credentials" {
  type        = string
  description = "Big Query credentials.json"
}

variable "contexts_function_available_memory" {
  type        = string
  default     = "256Mi"
  description = "Available memory for the contexts function"
}

variable "nodes_function_available_memory" {
  type        = string
  default     = "256Mi"
  description = "Available memory for the nodes function"
}
