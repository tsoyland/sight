# Requires a CNAME at Domeneshop: <hostname> -> output "container_hostname".
# Scaleway checks the CNAME and issues a Let's Encrypt certificate.
resource "scaleway_container_domain" "app" {
  count = var.enable_custom_domain ? 1 : 0

  container_id = scaleway_container.app.id
  hostname     = var.hostname
  region       = var.region
}
