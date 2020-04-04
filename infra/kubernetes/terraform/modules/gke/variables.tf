variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable location {
  description = "Location"
  default     = "europe-west1-b"
}

variable cluster_name {
  description = "Cluster name"
  default     = "cluster-1"
}

variable defaultpool_machine_type {
  description = "Machine type for default pool"
  default     = "n1-standard-2"
}

variable defaultpool_machine_size {
  description = "Machine boot disk size for default pool"
  default     = 20
}

variable "defaultpool_nodes_count" {
  description = "Cluster nodes count in the default pool"
  default     = 1
}

variable infrapool_machine_type {
  description = "Machine type for infra pool"
  default     = "n1-standard-2"
}

variable infrapool_machine_size {
  description = "Machine boot disk size for infra pool"
  default     = 20
}

variable "infrapool_nodes_count" {
  description = "Cluster nodes count in the infra pool"
  default     = 1
}

variable "min_master_version" {
  description = "The minimum version of the master"
  default     = "1.15.9-gke.24"
}

variable "subnetwork" {
  description = "The name or self_link of the Google Compute Engine subnetwork in which the cluster's instances are launched."
  default     = "default"
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to."
  default     = "none"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to."
  default     = "none"
}
