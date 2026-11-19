# Serverless SQL Database (PostgreSQL 16): scales to zero, so an idle demo only pays for storage.
# The first query after idle wakes it up (a few seconds).
resource "scaleway_sdb_sql_database" "main" {
  name    = var.app_name
  version = 16
  min_cpu = 0
  max_cpu = var.db_max_cpu
  region  = var.region
}

# Serverless SQL authenticates with IAM: username = IAM application ID, password = API secret key.
# A dedicated application keeps the container's credentials limited to read/write on this project's databases.
resource "scaleway_iam_application" "db" {
  name        = "${var.app_name}-db-app"
  description = "Used by the ${var.app_name} container to connect to its Serverless SQL Database"
  tags        = local.tags
}

resource "scaleway_iam_policy" "db" {
  name           = "${var.app_name}-db-access"
  description    = "Read/write access to Serverless SQL Databases in the ${var.app_name} project"
  application_id = scaleway_iam_application.db.id

  rule {
    project_ids          = [scaleway_sdb_sql_database.main.project_id]
    permission_set_names = ["ServerlessSQLDatabaseReadWrite"]
  }
}

resource "scaleway_iam_api_key" "db" {
  application_id     = scaleway_iam_application.db.id
  description        = "${var.app_name} container -> Serverless SQL Database"
  default_project_id = scaleway_sdb_sql_database.main.project_id
}

locals {
  # Endpoint looks like postgres://<id>.pg.sdb.fr-par.scw.cloud:5432/<database>?sslmode=require
  db_parts = regex("^postgres(?:ql)?://(?P<host>[^:/?]+):(?P<port>[0-9]+)/(?P<database>[^?]+)", scaleway_sdb_sql_database.main.endpoint)

  db_connection_string = join(";", [
    "Host=${local.db_parts.host}",
    "Port=${local.db_parts.port}",
    "Database=${local.db_parts.database}",
    "Username=${scaleway_iam_application.db.id}",
    "Password=${scaleway_iam_api_key.db.secret_key}",
    "SSL Mode=Require",
    # Allow for the database waking up from zero.
    "Timeout=30",
  ])
}
