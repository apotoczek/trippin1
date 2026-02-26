# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]

### Added
- Added a trip workflow Terraform module (DynamoDB table, Step Functions state machine, workflow Lambdas, and `/trips/start` API route) and wired it into `develop`, `staging`, and `prod` environments.
- Added Cognito auth verify/refresh Lambdas and HTTP API routes, plus environment outputs for verify/refresh/start-trip URLs.
- Added deploy-time rendering of the sign-in `index.html` with the API base URL and a CloudFront invalidation trigger tied to site content changes.
- Added Terraform provider lock files for each environment.

### Changed
- Changed the API auth module outputs to expose HTTP API ID and execution ARN, with auth URLs now derived in environment outputs.
- Changed the sign-in page to prefill the API base URL when deployed.
- Changed `.gitignore` to exclude `LOCAL_WORK_LOG.md` and the `docs/` directory.
- Changed the README to remove references to the `docs/` folder.
