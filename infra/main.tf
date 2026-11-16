locals {
  tags = ["app:${var.app_name}", "managed-by:opentofu"]
}

# Private Network shared by the container and the database, so the database has no public endpoint.
resource "scaleway_vpc_private_network" "main" {
  name   = "${var.app_name}-pn"
  region = var.region
  tags   = local.tags
}
