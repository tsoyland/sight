# Credentials come from SCW_ACCESS_KEY, SCW_SECRET_KEY and SCW_DEFAULT_PROJECT_ID.
provider "scaleway" {
  region = var.region
  zone   = "${var.region}-1"
}
