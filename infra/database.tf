resource "random_password" "db_admin" {
  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "-_=+#%"
}

resource "random_password" "db_app" {
  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "-_=+#%"
}

resource "scaleway_rdb_instance" "main" {
  name           = "${var.app_name}-db"
  node_type      = var.db_node_type
  engine         = "PostgreSQL-16"
  is_ha_cluster  = false
  disable_backup = false
  # Daily backups, kept for 7 days.
  backup_schedule_frequency = 24
  backup_schedule_retention = 7
  encryption_at_rest        = true

  user_name = "sightadmin"
  password  = random_password.db_admin.result

  # Only reachable from the Private Network: no public (load_balancer) endpoint.
  private_network {
    pn_id       = scaleway_vpc_private_network.main.id
    enable_ipam = true
  }

  region = var.region
  tags   = local.tags
}

resource "scaleway_rdb_database" "app" {
  instance_id = scaleway_rdb_instance.main.id
  name        = var.app_name
}

resource "scaleway_rdb_user" "app" {
  instance_id = scaleway_rdb_instance.main.id
  name        = var.app_name
  password    = random_password.db_app.result
  is_admin    = false
}

resource "scaleway_rdb_privilege" "app" {
  instance_id   = scaleway_rdb_instance.main.id
  user_name     = scaleway_rdb_user.app.name
  database_name = scaleway_rdb_database.app.name
  permission    = "all"
}

locals {
  db_endpoint = scaleway_rdb_instance.main.private_network[0]
  db_connection_string = join(";", [
    "Host=${local.db_endpoint.ip}",
    "Port=${local.db_endpoint.port}",
    "Database=${scaleway_rdb_database.app.name}",
    "Username=${scaleway_rdb_user.app.name}",
    "Password=${random_password.db_app.result}",
    # Traffic stays inside the Private Network; TLS is still required.
    "SSL Mode=Require",
    "Trust Server Certificate=true",
  ])
}
