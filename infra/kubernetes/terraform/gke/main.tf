provider "google" {
  version = "3.6.0"
  project = var.project
  region  = var.region
}

data "terraform_remote_state" "state" {
  backend = "gcs"

  config = {
    bucket = "kubernetes-tf-state-bucket-20190202001"
  }
}

module "gke" {
  source                   = "../modules/gke"
  project                  = var.project
  region                   = var.region
  location                 = var.location
  cluster_name             = var.cluster_name
  logging_service          = var.logging_service
  monitoring_service          = var.monitoring_service
  defaultpool_machine_type = var.defaultpool_machine_type

  defaultpool_machine_size = var.defaultpool_machine_size

  defaultpool_nodes_count = var.defaultpool_nodes_count

  infrapool_machine_type = var.infrapool_machine_type

  infrapool_machine_size = var.infrapool_machine_size

  infrapool_nodes_count = var.infrapool_nodes_count

  min_master_version = var.min_master_version
}

resource "google_compute_address" "gke_ip" {
  name = "primary"
}

