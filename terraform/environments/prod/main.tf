locals {
  repo_root = abspath("${path.root}/../../..")
  web_dir   = abspath("${path.root}/../../../web/signin")
}

data "archive_file" "lambda_bundle" {
  type        = "zip"
  source_dir  = local.repo_root
  output_path = "${path.root}/lambda_bundle.zip"

  excludes = [
    ".git",
    ".git/*",
    ".venv",
    ".venv/*",
    ".aws-sam",
    ".aws-sam/*",
    "terraform",
    "terraform/*",
    "tests",
    "tests/*",
    "docs",
    "docs/*",
    "local-ui",
    "local-ui/*",
    "env",
    "env/*",
    "*.pyc",
    "**/__pycache__/*"
  ]
}

module "api_auth" {
  source = "../../modules/api_auth"

  project_name                = var.project_name
  env_name                    = var.env_name
  region                      = var.region
  lambda_zip_path             = data.archive_file.lambda_bundle.output_path
  lambda_zip_hash             = data.archive_file.lambda_bundle.output_base64sha256
  cognito_user_pool_client_id = var.cognito_user_pool_client_id
  log_level                   = var.log_level
}

module "signin_site" {
  source = "../../modules/signin_site"

  project_name = var.project_name
  env_name     = var.env_name
  site_dir     = local.web_dir
}
