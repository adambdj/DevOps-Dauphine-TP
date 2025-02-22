terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.10"
    }
  }

  backend "gcs" {
    bucket = "bucket-adambdj95100"
  }

  required_version = ">= 1.0"
}


provider "google" {
    project = "devops4-401021"
}
