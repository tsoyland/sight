resource "scaleway_registry_namespace" "main" {
  name        = var.registry_namespace
  description = "Container images for ${var.app_name}"
  is_public   = false
  region      = var.region
}
