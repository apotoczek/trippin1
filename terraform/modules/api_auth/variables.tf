variable "project_name" {
  type = string
}

variable "env_name" {
  type = string
}

variable "region" {
  type = string
}

variable "lambda_zip_path" {
  type = string
}

variable "lambda_zip_hash" {
  type = string
}

variable "cognito_user_pool_client_id" {
  type      = string
  sensitive = true
}

variable "log_level" {
  type    = string
  default = "INFO"
}
