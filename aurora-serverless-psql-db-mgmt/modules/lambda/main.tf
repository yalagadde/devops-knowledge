module "this" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"

  function_name = var.function_name
  description = var.description
  handler = var.handler
  source_path = var.source_path
  create_package = var.create_package
  package_type = var.package_type
  runtime = var.runtime
  timeout = var.timeout
  memory_size = var.memory_size
  create_role = var.create_role
  lambda_role = var.lambda_role
  role_name = var.role_name
  policy_name = var.policy_name
  layers = var.layers

  tags = merge(
    var.tags
  )
}