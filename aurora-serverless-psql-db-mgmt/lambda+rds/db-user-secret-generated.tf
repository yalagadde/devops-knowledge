resource "random_password" "db_user_secrets" {
  for_each = local.db_users
  length   = 32
  numeric  = true
  upper    = true
  special  = false
}

resource "aws_secretsmanager_secret" "db_user_secrets" {
  for_each    = local.db_users
  name        = "rds-db-credentials/${module.psql_app_serverless_v2_db.this.cluster_resource_id}/${each.key}"
  description = "RDS database ${module.psql_app_serverless_v2_db.this.cluster_id} credentials for ${each.key}"
  kms_key_id  = data.aws_kms_key.secretsmanager.id
}

resource "aws_secretsmanager_secret_version" "db_user_secrets" {
  for_each  = aws_secretsmanager_secret.db_user_secrets
  secret_id = each.value.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = data.aws_rds_cluster.psql_app_serverless_v2_db.endpoint
    username = each.key
    password = random_password.db_user_secrets[each.key].result
    dbname   = data.aws_rds_cluster.psql_app_serverless_v2_db.database_name
    port     = "${data.aws_rds_cluster.psql_app_serverless_v2_db.port}"
  })
}

resource "aws_secretsmanager_secret_policy" "db_user_secrets" {
  for_each   = aws_secretsmanager_secret.db_user_secrets
  secret_arn = each.value.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Deny",
        Principal = "*",
        Action    = ["secretsmanager:GetSecretValue"],
        Resource  = each.value.arn,
        Condition = {
          StringNotLike = {
            "aws:userId" = flatten(concat([
              "*:${each.key}",
              "*:vyalagadde@palo-it.com"
            ]))
          },
          ArnNotEquals = {
            "aws:PrincipalArn" = "${module.lambda_rotate_db_secret.this.lambda_function_arn}"
          }
        }
      }
    ]
  })
}

resource "aws_secretsmanager_secret_rotation" "db_user_secrets" {
  for_each            = aws_secretsmanager_secret.db_user_secrets
  secret_id           = each.value.id
  rotation_lambda_arn = module.lambda_rotate_db_secret.this.lambda_function_arn
  rotation_rules {
    automatically_after_days = 1
  }
}