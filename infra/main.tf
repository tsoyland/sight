# Resources are added in milestone M1:
#   registry.tf  - Container Registry namespace
#   database.tf  - Managed PostgreSQL (DB-DEV-S)
#   container.tf - Serverless Container namespace + "sight" container (min/max scale 1)
#   domain.tf    - scaleway_container_domain for var.hostname (when enable_custom_domain = true)

locals {
  tags = ["app:${var.app_name}", "managed-by:opentofu"]
}
