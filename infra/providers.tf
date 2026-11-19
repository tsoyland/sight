# Credentials come from SCW_ACCESS_KEY, SCW_SECRET_KEY, SCW_DEFAULT_PROJECT_ID and SCW_DEFAULT_ORGANIZATION_ID.
provider "scaleway" {
  region = var.region
  zone   = "${var.region}-1"
}
