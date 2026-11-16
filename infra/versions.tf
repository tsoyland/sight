terraform {
  required_version = ">= 1.8.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.60"
    }
  }

  # State lives in a Scaleway Object Storage bucket (S3-compatible).
  # The bucket is created once by hand (see infra/README.md) and the
  # access keys are passed via AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.
  # Enabled in M1 together with `tofu init -backend-config=...`.
  # backend "s3" {}
}
