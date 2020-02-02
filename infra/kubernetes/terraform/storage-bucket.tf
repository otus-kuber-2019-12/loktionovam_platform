provider "google" {
  version = "3.6.0"
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "storage-bucket" {
  name     = "kubernetes-tf-state-bucket-20190202001"
  location = "EU"
}

output "storage-bucket_url" {
  value = google_storage_bucket.storage-bucket.url
}

