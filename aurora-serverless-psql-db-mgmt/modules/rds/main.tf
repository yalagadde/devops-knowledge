module "this" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "9.12.0"

  name              = var.name
  engine            = data.aws_rds_engine_version.postgresql.engine
  engine_mode       = var.engine_mode
  engine_version    = data.aws_rds_engine_version.postgresql.version
  storage_encrypted = var.storage_encrypted
  database_name = var.database_name
  master_username   = var.master_username
  manage_master_user_password = true
  security_group_name = var.security_group_name
  domain_iam_role_name = var.domain_iam_role_name
  vpc_id  = var.vpc_id
  db_subnet_group_name = var.db_subnet_group_name
  subnets = var.subnets
  create_db_subnet_group = var.create_db_subnet_group
  create_security_group = var.create_security_group
#   vpc_id               = module.vpc.vpc_id
#   db_subnet_group_name = module.vpc.database_subnet_group_name
#   security_group_rules = {
#     vpc_ingress = {
#       cidr_blocks = module.vpc.private_subnets_cidr_blocks
#     }
#   }

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true
  enable_http_endpoint = true
  copy_tags_to_snapshot = true

  serverlessv2_scaling_configuration = {
    min_capacity             = 0.5
    max_capacity             = 2
    # seconds_until_auto_pause = 3600
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
  }

  tags = merge(var.tags)
}