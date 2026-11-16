resource "scaleway_container_namespace" "main" {
  name        = var.app_name
  description = "Serverless containers for ${var.app_name}"
  region      = var.region
  tags        = local.tags
}

resource "scaleway_container" "app" {
  name         = var.app_name
  namespace_id = scaleway_container_namespace.main.id
  image        = "${scaleway_registry_namespace.main.endpoint}/${var.app_name}:${var.image_tag}"
  port         = 8080
  protocol     = "http1"
  privacy      = "public"

  # 560 mVCPU / 1 GiB is one of Scaleway's standard size pairs.
  cpu_limit          = 560
  memory_limit_bytes = 1024 * 1024 * 1024

  # max_scale stays 1 until SignalR gets a Redis backplane (see plan).
  min_scale = var.min_scale
  max_scale = 1

  # Longest allowed request duration; SignalR WebSockets count as one long request.
  timeout = 900

  https_connections_only = true
  private_network_id     = scaleway_vpc_private_network.main.id

  environment_variables = {
    ASPNETCORE_ENVIRONMENT = "Production"
  }

  secret_environment_variables = {
    ConnectionStrings__Sight = local.db_connection_string
  }

  # Probes only check the process (/health/live); /health also checks the database.
  startup_probe {
    failure_threshold = 30
    interval          = "2s"
    timeout           = "2s"
    http {
      path = "/health/live"
    }
  }

  liveness_probe {
    failure_threshold = 3
    interval          = "30s"
    timeout           = "5s"
    http {
      path = "/health/live"
    }
  }

  region = var.region
  tags   = local.tags

  depends_on = [scaleway_rdb_privilege.app]
}
