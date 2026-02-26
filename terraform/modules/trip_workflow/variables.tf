variable "project_name" {
  type = string
}

variable "env_name" {
  type = string
}

variable "lambda_zip_path" {
  type = string
}

variable "lambda_zip_hash" {
  type = string
}

variable "http_api_id" {
  type = string
}

variable "http_api_execution_arn" {
  type = string
}

variable "log_level" {
  type    = string
  default = "INFO"
}
