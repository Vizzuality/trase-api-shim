variable "project" {
  type        = string
  description = "The GCP project to deploy service into"
}

variable "region" {
  type        = string
  description = "The GCP region to deploy service into"
}

variable "name" {
  type        = string
  description = "Name to use on resources"
}

variable "dns_managed_zone_name" {
  type        = string
  description = "Name of the DNS Zone"
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



variable "contexts_function_name" {
  type        = string
  description = "Name of the contexts Cloud Function"
}

variable "functions_path_prefix" {
  type        = string
  description = "Path prefix for the functions services"
}

variable "contexts_function_path_prefix" {
  type        = string
  description = "Path prefix for the contexts function"
}

