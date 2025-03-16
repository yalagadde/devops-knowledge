module "psql_app_serverless_v2_db" {
  source = "../modules/rds"

  name                   = "psql-app-database"
  engine_mode            = "provisioned"
  master_username        = "psql_admin"
  security_group_name    = "sgrp-psql-app-database"
  database_name          = "app"
  domain_iam_role_name   = "iamr-psql-app-database"
  vpc_id                 = data.aws_vpc.default_vpc_id.id
  db_subnet_group_name   = "psql-app-database-subnet-group"
  subnets                = data.aws_subnets.default_subnets.ids
  create_db_subnet_group = true
  create_security_group  = true

  tags = {
    Environment = "dev"
    Project     = "aurora-serverless"
    Zone        = "db-zone"
  }
}