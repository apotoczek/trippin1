# CI/CD to AWS Setup (GitHub Actions + OIDC)

This repo includes workflow:
- `.github/workflows/terraform-cicd.yml`

It deploys by branch:
- `develop` -> GitHub environment `develop`
- `staging` -> GitHub environment `staging`
- `main` -> GitHub environment `prod`

Manual deploy is also available via `workflow_dispatch`.

## 1. Create AWS OIDC provider (one-time per AWS account)

If not already present, create IAM OIDC provider for GitHub:

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

## 2. Create IAM role(s) for GitHub Actions

You can use one role per environment (recommended) or one shared role.

Trust policy example for repo `apotoczek/trippin1`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:apotoczek/trippin1:ref:refs/heads/develop",
            "repo:apotoczek/trippin1:ref:refs/heads/staging",
            "repo:apotoczek/trippin1:ref:refs/heads/main",
            "repo:apotoczek/trippin1:environment:develop",
            "repo:apotoczek/trippin1:environment:staging",
            "repo:apotoczek/trippin1:environment:prod"
          ]
        }
      }
    }
  ]
}
```

Minimum permissions for the role:
- Terraform backend access (S3 state bucket + DynamoDB lock table)
- IAM/Lambda/API Gateway/CloudFront/S3 permissions used by this stack

For initial bootstrap, easiest path is broad admin role, then tighten to least privilege after first successful deploy.

## 3. Create Terraform backend resources

Create once (names are examples):
- S3 bucket: `trip-planner-tfstate`
- DynamoDB lock table: `trip-planner-tf-locks`

## 4. Configure GitHub Environments

Create environments in repo settings:
- `develop`
- `staging`
- `prod`

Add protection rules:
- Require approval for `prod`

## 5. Add environment secrets/variables

In each GitHub environment, set:

Secrets:
- `AWS_ROLE_ARN`: IAM role ARN to assume for that environment
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state
- `TF_LOCK_TABLE`: DynamoDB table name for Terraform lock
- `COGNITO_USER_POOL_CLIENT_ID`: Cognito app client id for that env

Variables:
- `AWS_REGION` (example: `us-east-1`)
- `PROJECT_NAME` (example: `trip-planner`)

Automation helper:
- `tools/setup_github_envs.sh`
  - Creates `develop`, `staging`, `prod` environments
  - Sets required vars/secrets for each environment
  - Default Cognito values are `changeme` unless you pass:
    - `COGNITO_DEVELOP`
    - `COGNITO_STAGING`
    - `COGNITO_PROD`

## 6. Trigger deploys

- Push to `develop`, `staging`, or `main` branch.
- Or run workflow manually and choose environment.

## 7. Verify outputs

Workflow summary includes:
- `api_base_url`
- `signin_url`

Use `signin_url` (HTTPS CloudFront URL), then paste `api_base_url` into sign-in page.
