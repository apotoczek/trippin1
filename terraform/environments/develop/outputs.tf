output "api_base_url" {
  value = module.api_auth.api_base_url
}

output "auth_start_url" {
  value = "${module.api_auth.api_base_url}/auth/start"
}

output "auth_verify_url" {
  value = "${module.api_auth.api_base_url}/auth/verify"
}

output "auth_refresh_url" {
  value = "${module.api_auth.api_base_url}/auth/refresh"
}

output "start_trip_url" {
  value = "${module.api_auth.api_base_url}/trips/start"
}

output "signin_url" {
  value = module.signin_site.site_url
}

output "signin_bucket_name" {
  value = module.signin_site.bucket_name
}

output "cognito_define_auth_challenge_arn" {
  value = module.api_auth.cognito_define_auth_challenge_arn
}

output "cognito_create_auth_challenge_arn" {
  value = module.api_auth.cognito_create_auth_challenge_arn
}

output "cognito_verify_auth_challenge_arn" {
  value = module.api_auth.cognito_verify_auth_challenge_arn
}
