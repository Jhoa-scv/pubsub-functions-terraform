# cant use vars to set the bucket prefix :(
terraform {
  backend "gcs" {
    bucket = "artifacts.optoro-playground-rm.appspot.com"
    prefix = "environments/optoro-playground-rm"
  }
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.6.0"
    }
  }
}

provider "google" {
  project     =  "<id proyecto>"
  region      = "us-central1"
  credentials = "<reemplaza con el file generado>"
}

provider "google-beta" {
  project     =  "<id proyecto>"
  region      = "us-central1"
  credentials = "<reemplaza con el file generado>"
}

terraform {
  required_version = "1.3.0"
}
