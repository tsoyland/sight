terraform {
  required_version = ">= 1.8.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # State lives in a Scaleway Object Storage bucket (S3-compatible).
  # Settings are in backend.hcl:  tofu init -backend-config=backend.hcl
  # Credentials: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY = your Scaleway access/secret key.
  backend "s3" {}
}
