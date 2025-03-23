module "create_postgres_user_read_only_role" {

  source  = "digitickets/cli/aws"
  version = "7.0.0"

  role_session_name = "CreatePostgresUserRoles"
  aws_cli_commands = [
    "rds-data", "execute-statement",
    format("--resource-arn=%s", module.psql_app_serverless_v2_db.this.cluster_arn),
    format("--secret-arn=%s", data.aws_secretsmanager_secret.rds_cluster.arn),
    format("--database=%s", local.rds_database_name),
    format("--sql=\"%s\"", local.sql_create_read_only_role.sql)
  ]
}

module "create_postgres_user_read_write_role" {

  source  = "digitickets/cli/aws"
  version = "7.0.0"

  role_session_name = "CreatePostgresUserRoles"
  aws_cli_commands = [
    "rds-data", "execute-statement",
    format("--resource-arn=%s", module.psql_app_serverless_v2_db.this.cluster_arn),
    format("--secret-arn=%s", data.aws_secretsmanager_secret.rds_cluster.arn),
    format("--database=%s", local.rds_database_name),
    format("--sql=\"%s\"", local.sql_create_read_write_role.sql)
  ]

  depends_on = [
    module.create_postgres_user_read_only_role
  ]
}

module "create_postgres_user_admin_role" {

  source  = "digitickets/cli/aws"
  version = "7.0.0"

  role_session_name = "CreatePostgresUserRoles"
  aws_cli_commands = [
    "rds-data", "execute-statement",
    format("--resource-arn=%s", module.psql_app_serverless_v2_db.this.cluster_arn),
    format("--secret-arn=%s", data.aws_secretsmanager_secret.rds_cluster.arn),
    format("--database=%s", local.rds_database_name),
    format("--sql=\"%s\"", local.sql_create_admin_role.sql)
  ]

  depends_on = [
    module.create_postgres_user_read_write_role
  ]
}

# Create a SQL users
module "create_postgres_user" {
  for_each = {
    for user, user_info in local.sql_users_map :
    user => user_info
    if var.env_name != "localstack"
  }

  source  = "digitickets/cli/aws"
  version = "7.0.0"

  role_session_name = "CreatePostgresUser"
  aws_cli_commands = [
    "rds-data", "execute-statement",
    format("--resource-arn=%s", module.psql_app_serverless_v2_db.this.cluster_arn),
    format("--secret-arn=%s", data.aws_secretsmanager_secret.rds_cluster.arn),
    format("--database=%s", local.rds_database_name),
    format("--sql=\"%s\"", local.sql_create_user[each.key].sql)
  ]
}

# Require improvements, so commented out
# # Fetch existing SQL users
# module "fetch_existing_sql_users" {
#   source  = "digitickets/cli/aws"
#   version = "7.0.0"

#   role_session_name = "FetchExistingSqlUsers"
#   aws_cli_commands = [
#     "rds-data", "execute-statement",
#     format("--resource-arn=%s", module.psql_app_serverless_v2_db.this.cluster_arn),
#     format("--secret-arn=%s", data.aws_secretsmanager_secret.rds_cluster.arn),
#     format("--database=%s", local.rds_database_name),
#     format("--sql=\"%s\"", local.sql_fetch_existing_users.sql),
#   ]
# }

# # Drop a SQL user
# module "drop_postgres_user" {
#   for_each = local.sql_drop_user

#   source  = "digitickets/cli/aws"
#   version = "7.0.0"

#   role_session_name = "DropUsers"
#   aws_cli_commands = [
#     "rds-data", "execute-statement",
#     format("--resource-arn=%s", module.psql_app_serverless_v2_db.this.cluster_arn),
#     format("--secret-arn=%s", data.aws_secretsmanager_secret.rds_cluster.arn),
#     format("--database=%s", local.rds_database_name),
#     format("--sql=\"%s\"", each.value.sql),
#   ]
# }