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
  default     = "g1-small"
}

variable defaultpool_machine_size {
  description = "Machine boot disk size for default pool"
  default     = 20
}

variable "defaultpool_nodes_count" {
  description = "Cluster nodes count in the default pool"
  default     = 1
}

variable "min_master_version" {
  description = "The minimum version of the master"
  default     = "1.15.8-gke.2"
}

variable "subnetwork" {
  description = "The name or self_link of the Google Compute Engine subnetwork in which the cluster's instances are launched."
  default     = "default"
}
