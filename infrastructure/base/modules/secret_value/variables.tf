variable "key" {
  type = string
}

variable "value" {
  type    = any
  default = null
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP project id"
}

variable "use_random_value" {
  type    = bool
  default = false
}


variable "random_value_length" {
  type    = number
  default = 32
}
