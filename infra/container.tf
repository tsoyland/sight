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

  # 280 mVCPU / 512 MiB: the smallest standard size that runs .NET comfortably for demos.
  cpu_limit          = 280
  memory_limit_bytes = 512 * 1024 * 1024

  # max_scale stays 1 until SignalR gets a Redis backplane (see plan).
  min_scale = var.min_scale
  max_scale = 1

  # Longest allowed request duration; SignalR WebSockets count as one long request.
  timeout = 900

  https_connections_only = true

  environment_variables = {
    ASPNETCORE_ENVIRONMENT = "Production"
  }

  secret_environment_variables = {
    ConnectionStrings__Sight = local.db_connection_string
  }

  # Probes only check the process (/health/live); /health also checks the database.
  startup_probe {
    # Up to ~60 s for a cold start (Scaleway requires interval >= 5s).
    failure_threshold = 12
    interval          = "5s"
    timeout           = "3s"
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

  depends_on = [scaleway_iam_policy.db]
}
