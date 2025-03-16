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

# Lambda function for secret rotation (if it exists already)
data "aws_lambda_function" "psql_rotate_secret" {
  function_name = module.lambda_rotate_db_secret.this.lambda_function_name
}
