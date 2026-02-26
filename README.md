# Trip Planner Project

Scaffold aligned to AWS API Gateway + Lambda + Step Functions, with Cognito-based phone OTP auth entrypoints.

Local runbook:
- `LOCAL_SETUP.md`

## Project Structure

- `infra/template.yaml`
  - AWS SAM template for API, auth lambdas, trip workflow lambdas, DynamoDB table, and Step Functions state machine
- `terraform/`
  - Terraform modules and per-environment roots (`develop`, `staging`, `prod`)
- `src/common/`
  - shared response helpers
- `src/lambdas/`
  - `auth_start_otp/` - starts Cognito custom auth flow
  - `auth_verify_otp/` - verifies OTP challenge and returns tokens
  - `auth_refresh/` - refreshes tokens
  - `start_trip/` - starts Step Functions execution
  - `local_trip_preview/` - local-only trip preview endpoint for HTML testing
  - `get_flags/`, `geocode/`, `route_basic/`, `score/`, `persist/` - workflow steps
- `local-ui/`
  - static HTML page to exercise local SAM endpoint and render map preview
- `tests/`
  - basic smoke test
- `web/signin/`
  - static sign-in page deployed to S3 + CloudFront (HTTPS)
- `env/examples/`
  - local env-file templates for local/dev/staging/prod workflows

## Basic Auth Flow (Scaffold)

1. `POST /auth/start`
2. `POST /auth/verify`
3. `POST /auth/refresh`

This scaffold assumes a Cognito User Pool App Client configured for `CUSTOM_AUTH` challenge behavior.

## Quick Start

1. Install dependencies:
   - `python -m venv .venv && source .venv/bin/activate`
   - `pip install -r requirements.txt`
2. Update `USER_POOL_CLIENT_ID` placeholders in `infra/template.yaml`.
3. Deploy with SAM (example):
   - `sam build -t infra/template.yaml`
   - `sam deploy --guided`
4. Run tests:
   - `pytest`

## Terraform Deployment (Develop/Staging/Prod)

Use the Terraform scaffolding in `terraform/environments/<env>` to deploy:
1. API Gateway HTTP API + Lambda (`POST /auth/start`) with AWS HTTPS endpoint.
2. HTTPS sign-in page via CloudFront.

Quick example (develop):
1. `cp terraform/environments/develop/terraform.tfvars.example terraform/environments/develop/terraform.tfvars`
2. `cd terraform/environments/develop`
3. `export TF_VAR_cognito_user_pool_client_id=\"<your-client-id>\"`
4. `terraform init`
5. `terraform apply -var-file=terraform.tfvars`
6. `terraform output api_base_url`
7. `terraform output signin_url`

## Local Development

All local run/debug/test instructions are centralized in:
- `LOCAL_SETUP.md`

## Next Steps

- Add Cognito custom challenge Lambdas (Define/Create/Verify Auth Challenge triggers)
- Wire API authorizer to protect trip endpoints
- Implement real geocoding/routing/score integrations
- Add integration tests for auth and workflow
