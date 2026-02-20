# Terraform Layout

- `modules/api_auth`: Lambda + HTTP API for auth start endpoint
- `modules/signin_site`: S3 + CloudFront HTTPS static site
- `environments/develop|staging|prod`: environment roots

## Workflow

1. Enter environment folder.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and set non-secret values.
3. Export secret variables via shell/CI (`TF_VAR_cognito_user_pool_client_id`).
4. `terraform init && terraform apply -var-file=terraform.tfvars`

## Remote state

Each environment includes `backend.hcl.example`.
Create your backend resources (S3 + DynamoDB lock table), then initialize with:

```bash
terraform init -backend-config=backend.hcl
```
