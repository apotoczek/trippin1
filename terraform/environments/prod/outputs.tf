output "api_base_url" {
  value = module.api_auth.api_base_url
}

output "auth_start_url" {
  value = module.api_auth.auth_start_url
}

output "signin_url" {
  value = module.signin_site.site_url
}

output "signin_bucket_name" {
  value = module.signin_site.bucket_name
}
