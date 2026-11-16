# Used with: tofu init -backend-config=backend.hcl
# The bucket is created once by hand (see infra/README.md). Bucket names are global on Scaleway,
# so change it here if the name is taken.
bucket = "sight-tobba-tofu-state"
key    = "sight/terraform.tfstate"
region = "fr-par"

endpoints = {
  s3 = "https://s3.fr-par.scw.cloud"
}

# Scaleway is S3-compatible but not AWS: skip AWS-only checks.
skip_credentials_validation = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
skip_s3_checksum            = true
