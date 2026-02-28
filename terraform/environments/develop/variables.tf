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

variable "cognito_user_pool_id" {
  type    = string
  default = ""
}

variable "log_level" {
  type    = string
  default = "INFO"
}

variable "otp_static_code" {
  type    = string
  default = ""
}

variable "otp_disable_sms" {
  type    = bool
  default = false
}
