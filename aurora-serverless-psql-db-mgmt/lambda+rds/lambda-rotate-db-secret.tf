resource "aws_lambda_layer_version" "psycopg2_layer" {
  layer_name          = "psycopg2-layer"
  description         = "Psycopg2 PostgreSQL driver for AWS Lambda"
  compatible_runtimes = ["python3.9"]
  filename            = "./psycopg2-layer.zip"
}

# module "lambda_psycopg2_layer" {
#   source = "../modules/lambda"

#   create_layer = true
#   layer_name          = "psycopg2-layer"
#   description         = "Psycopg2 PostgreSQL driver for AWS Lambda"
#   compatible_runtimes = ["python3.9"]
#   source_path = "./psycopg2-layer.zip"

#   tags = {
#     Environment = "dev"
#     Project     = "aurora-serverless"
#     Zone        = "db-zone"
#   }
# }

module "lambda_rotate_db_secret" {
  source = "../modules/lambda"

  function_name      = "lbda-rotate-db-secret"
  description        = "Rotate Aurora Serverless PostgreSQL DB secret"
  handler            = "lambda_function.lambda_handler"
  source_path        = "./lambda_function.py"
  create_package     = true
  package_type       = "Zip"
  runtime            = "python3.9"
  timeout            = 30
  memory_size        = 128
  layers             = [aws_lambda_layer_version.psycopg2_layer.arn]
  create_role        = true
  role_name          = "iamr-lbda-rotate-db-secret-role"
  policy_name        = "iamp-lbda-rotate-db-secret-policy"
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "AllowKMS"
      },
      {
        Action = [
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "AllowSecretsManager"
      },
      {
        Action   = "secretsmanager:GetRandomPassword"
        Effect   = "Allow"
        Resource = "*"
        Sid      = "AllowSecretsManagerRandomPassword"
      }
    ]
  })

  # layers attribute should be moved to the aws_lambda_function resource inside the module

  tags = {
    Environment = "dev"
    Project     = "aurora-serverless"
    Zone        = "db-zone"
  }
}
