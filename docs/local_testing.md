# Local Testing UI (Not for Production Deployment)

This project includes a local-only testing endpoint and static HTML UI for quick Lambda logic validation.

## What is local-only

- Lambda endpoint: `GET /local/trip-preview`
- Static page: `local-ui/index.html`

The endpoint is controlled by SAM parameter `EnableLocalTestTools` and defaults to `false`.

## Run locally

1. Start SAM local API with local tools enabled:
   - `sam local start-api -t infra/template.yaml --parameter-overrides EnableLocalTestTools=true`
2. Start static HTML server in another terminal:
   - `python3 -m http.server 8080 --directory local-ui`
3. Open:
   - `http://127.0.0.1:8080`

## Production safety

- Keep `EnableLocalTestTools=false` for normal deploys.
- Do not set this parameter to true in production environments.
