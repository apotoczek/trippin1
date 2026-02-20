variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "env_name" {
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
