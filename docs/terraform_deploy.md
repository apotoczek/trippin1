# Terraform Deployment Guide

This project now includes Terraform scaffolding for three environments:

- `terraform/environments/develop`
- `terraform/environments/staging`
- `terraform/environments/prod`

Each environment deploys:

- Lambda + HTTP API (`POST /auth/start`) with random AWS HTTPS endpoint
- S3 + CloudFront sign-in page with HTTPS URL

## Should Terraform files be in GitHub?

Yes. Commit all Terraform code and module files.

Do not commit:

- `*.tfstate*`
- real `.tfvars` files containing secrets
- `.env.*` files with secrets

## Local vs cloud secrets strategy

- Local development: use `.env` files from `env/examples/` as templates.
- Cloud (develop/staging/prod): use environment-scoped secrets.
  - GitHub Actions environments: `develop`, `staging`, `prod`
  - Store `TF_VAR_cognito_user_pool_client_id` in each environment secret
  - Optional: move app secrets to AWS Secrets Manager or SSM Parameter Store

## Deploy (example: develop)

1. Prepare env vars locally:

```bash
cp env/examples/.env.develop.example .env.develop
# edit with real values
set -a; source .env.develop; set +a
```

2. Initialize Terraform for selected environment:

```bash
cd terraform/environments/develop
terraform init
```

3. Optional remote state (recommended):

```bash
terraform init -backend-config=backend.hcl
```

Use `backend.hcl.example` as template.

4. Plan and apply:

```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

If you avoid `terraform.tfvars`, pass non-secret vars via CLI and secrets via `TF_VAR_...` env vars.

5. Get URLs:

```bash
terraform output api_base_url
terraform output signin_url
```

## Sign-in page usage

Open `signin_url` output over HTTPS and paste `api_base_url` into the form.

## Notes

- This is scaffold infra. You can extend it to include full workflow Lambdas and Step Functions.
- Keep `local-ui/` and SAM local testing workflow for local-only testing.
