provider "google" {
  version = "3.6.0"
  project = var.project
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.location
  min_master_version = var.min_master_version
  subnetwork         = var.subnetwork
  logging_service    = var.logging_service
  monitoring_service    = var.monitoring_service
  node_pool {
    name       = "default-pool"
    node_count = var.defaultpool_nodes_count

    node_config {
      machine_type = var.defaultpool_machine_type
      disk_size_gb = var.defaultpool_machine_size
    }
  }
  node_pool {
    name       = "infra-pool"
    node_count = var.infrapool_nodes_count

    node_config {
      machine_type = var.infrapool_machine_type
      disk_size_gb = var.infrapool_machine_size
    }
  }

}

resource "google_compute_firewall" "firewall_kubernetes" {
  name    = "allow-kubernetes"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
}
