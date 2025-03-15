variable "tags" {
  description = "A map of tags to add to all the resource"
  type = object({
    Project = string
    Environment = string
    Zone    =   string 
  })
}

variable "create_role" {
  description = "Controls whether the IAM role for the Lambda function should be created"
  type = bool
  default = false
}

variable "lambda_role" {
  description = "IAM role attached to the Lambda function"
  type = string
  default = ""
}

variable "role_name" {
  description = "Name of the IAM role to use for Lambda function"
  type = string
  default = ""
}

variable "function_name" {
  description = "Name of the lambda function"
  type = string
  default = ""
}

variable "description" {
  description = "Description of the lambda function"
  type = string
}

variable "handler" {
  description = "Lambda function handler"
  type = string
  default = ""
}

variable "source_path" {
  description = "Lambda source code path"
  type = string
}

variable "create_package" {
  description = "Create lambda function package"
  type = bool
  default = false
}

variable "package_type" {
  description = "Lambda function package type"
  type = string
  default = ""
}

variable "runtime" {
  description = "Lambda execution function run time"
  type = string
  default = ""
}

variable "timeout" {
  description = "Lambda function timeout"
  type = number
  default = 3
}

variable "memory_size" {
  description = "Lambda function execution memory allocated"
  type = number
  default = 128
}

variable "environment_variables" {
  description = "Lambda function environment variables"
  type = object({
  })
  default = null
}

variable "policy_name" {
  description = "Name of the IAM policy to use for Lambda function"
  type = string
  default = ""
}

variable "attach_policy_json" {
  description = "Attach policy JSON to the IAM role"
  type = bool
  default = false
}

variable "policy_json" {
  description = "IAM policy JSON"
  type = string
  default = ""
}

variable "create_layer" {
  description = "Lambda function layer"
  type = bool
  default = false
}

variable "layer_name" {
  description = "Lambda function layer name"
  type = string
  default = ""
}

variable "compatible_runtimes" {
  description = "Lambda layer compatible runtime"
  type = list(string)
  default = null
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = null
}