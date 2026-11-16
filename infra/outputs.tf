output "container_hostname" {
  description = "Default Scaleway hostname of the app. Point the Domeneshop CNAME here."
  value       = trimsuffix(trimprefix(scaleway_container.app.public_endpoint, "https://"), "/")
}

output "app_url" {
  description = "URL the app is served on."
  value       = var.enable_custom_domain ? "https://${var.hostname}" : "https://${trimsuffix(trimprefix(scaleway_container.app.public_endpoint, "https://"), "/")}"
}

output "registry_endpoint" {
  description = "Push images here, e.g. <endpoint>/sight:<tag>."
  value       = scaleway_registry_namespace.main.endpoint
}

output "image_tag" {
  description = "Image tag currently deployed."
  value       = var.image_tag
}

output "min_scale" {
  description = "Current minimum number of running instances."
  value       = var.min_scale
}

output "database_private_endpoint" {
  description = "Private Network address of PostgreSQL."
  value       = "${local.db_endpoint.ip}:${local.db_endpoint.port}"
}
