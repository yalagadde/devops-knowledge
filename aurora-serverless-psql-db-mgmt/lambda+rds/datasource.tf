data "aws_vpc" "default_vpc_id" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc_id.id]
  }
}

data "aws_caller_identity" "this" {
}

data "aws_rds_cluster" "psql_app_serverless_v2_db" {
  # Important: This reference must be dependent on the module creating the cluster
  # so it only runs after the cluster exists
  cluster_identifier = module.psql_app_serverless_v2_db.this.cluster_id
  depends_on         = [module.psql_app_serverless_v2_db]
}

# Default KMS key for Secrets Manager
data "aws_kms_key" "secretsmanager" {
  key_id = "alias/aws/secretsmanager"
}

data "aws_secretsmanager_secret" "rds_cluster" {
  arn = module.psql_app_serverless_v2_db.this.cluster_master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret" "rds_user_password" {
  for_each = local.sql_users_map
  name     = "rds-db-credentials/${module.psql_app_serverless_v2_db.this.cluster_resource_id}/${each.key}"

  depends_on = [aws_secretsmanager_secret_version.db_user_secrets]
}

data "aws_secretsmanager_secret_version" "rds_user_password" {
  for_each  = local.sql_users_map
  secret_id = data.aws_secretsmanager_secret.rds_user_password[each.key].id
}