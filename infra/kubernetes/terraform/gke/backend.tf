terraform {
  backend "gcs" {
    bucket = "kubernetes-tf-state-bucket-20190202001"
    prefix = "gke/terraform/state"
  }
}

