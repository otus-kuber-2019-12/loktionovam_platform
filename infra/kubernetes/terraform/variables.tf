variable "project" {
  description = "Project ID"
}

variable "region" {
  description = "Region"
  default     = "europe-west1"
}

variable "organization" {
  description = "Organization name"
  default     = "otus"
}

variable "stage" {
  description = "Stage, e.g. 'prod', 'staging', 'dev"
  default     = "dev"
}
