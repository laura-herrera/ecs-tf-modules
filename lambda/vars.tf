variable "cluster_name" {}
variable "environment" {}
variable "lambda_file_name" {}
variable "lambda_function_name" {}
variable "lambda_function_handler" {}
variable "lambda_function_runtime" {}
variable "lambda_function_env_vars" { type = "map" }
variable "lambda_function_role_name" {}
variable "policies" { type = "list" }
variable "add_inline_policy" {}
variable "inline_policy_name" {}
variable "inline_policy_content" {}
