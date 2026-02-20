# Trip Planner Project

Scaffold aligned to the architecture docs: AWS API Gateway + Lambda + Step Functions, with Cognito-based phone OTP auth entrypoints.

## Project Structure

- `docs/`
  - `architecture.md`
  - `chat_history.md`
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

Reference guide:
- `docs/terraform_deploy.md`

Quick example (develop):
1. `cp terraform/environments/develop/terraform.tfvars.example terraform/environments/develop/terraform.tfvars`
2. `cd terraform/environments/develop`
3. `export TF_VAR_cognito_user_pool_client_id=\"<your-client-id>\"`
4. `terraform init`
5. `terraform apply -var-file=terraform.tfvars`
6. `terraform output api_base_url`
7. `terraform output signin_url`

## Local HTML + SAM Testing (No Prod)

1. Start local SAM API with local tools enabled:
   - `sam local start-api -t infra/template.yaml --parameter-overrides EnableLocalTestTools=true`
2. Serve static HTML in a second terminal:
   - `python3 -m http.server 8080 --directory local-ui`
3. Open:
   - `http://127.0.0.1:8080`

This local route (`GET /local/trip-preview`) is disabled by default and only created when `EnableLocalTestTools=true`.
For AWS production deploys, keep `EnableLocalTestTools=false`.

## Local SAM + Debugging (PyCharm)

1. Run preflight:
   - `python3 tools/preflight_debug.py`
2. In PyCharm, create `Python Debug Server`:
   - Host: `localhost`
   - Port: `5891`
   - Path mapping (one mapping only): `<repo-root> -> /var/task`
3. Start SAM with debugger enabled:
   - `DEBUG=true PYCHARM_DEBUG_HOST=host.docker.internal PYCHARM_DEBUG_PORT=5891 sam local start-api -t infra/template.yaml --parameter-overrides EnableLocalTestTools=true --port 3000`
4. Hit local endpoint:
   - `curl "http://127.0.0.1:3000/local/trip-preview?from_address=Seattle,WA&to_address=Portland,OR"`

Smoke test helper:
- `make test-local PYENV_ENV=<your-pyenv-env>`

## Next Steps

- Add Cognito custom challenge Lambdas (Define/Create/Verify Auth Challenge triggers)
- Wire API authorizer to protect trip endpoints
- Implement real geocoding/routing/score integrations
- Add integration tests for auth and workflow
