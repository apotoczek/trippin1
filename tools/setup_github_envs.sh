#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-apotoczek/trippin1}"
ACCOUNT_ID="${ACCOUNT_ID:-596833524375}"
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-trip-planner}"
TF_STATE_BUCKET="${TF_STATE_BUCKET:-trip-planner-tfstate-596833524375}"
TF_LOCK_TABLE="${TF_LOCK_TABLE:-trip-planner-tf-locks}"

COGNITO_DEVELOP="${COGNITO_DEVELOP:-changeme}"
COGNITO_STAGING="${COGNITO_STAGING:-changeme}"
COGNITO_PROD="${COGNITO_PROD:-changeme}"

create_env() {
  local env_name="$1"
  gh api --method PUT -H "Accept: application/vnd.github+json" "/repos/${REPO}/environments/${env_name}" >/dev/null
}

configure_env() {
  local env_name="$1"
  local role_name="$2"
  local cognito_client_id="$3"

  gh variable set AWS_REGION --env "$env_name" --repo "$REPO" --body "$AWS_REGION"
  gh variable set PROJECT_NAME --env "$env_name" --repo "$REPO" --body "$PROJECT_NAME"

  gh secret set AWS_ROLE_ARN --env "$env_name" --repo "$REPO" --body "arn:aws:iam::${ACCOUNT_ID}:role/${role_name}"
  gh secret set TF_STATE_BUCKET --env "$env_name" --repo "$REPO" --body "$TF_STATE_BUCKET"
  gh secret set TF_LOCK_TABLE --env "$env_name" --repo "$REPO" --body "$TF_LOCK_TABLE"
  gh secret set COGNITO_USER_POOL_CLIENT_ID --env "$env_name" --repo "$REPO" --body "$cognito_client_id"
}

create_env develop
create_env staging
create_env prod

configure_env develop GitHubActionsTripPlannerDevelop "$COGNITO_DEVELOP"
configure_env staging GitHubActionsTripPlannerStaging "$COGNITO_STAGING"
configure_env prod GitHubActionsTripPlannerProd "$COGNITO_PROD"

echo "GitHub environments/secrets/variables configured for ${REPO}."
