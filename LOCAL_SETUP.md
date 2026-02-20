# Local Setup README

This is the single local setup guide for running and testing this project on your machine.

## What You Can Run Locally

- SAM local API for Lambda logic
- Local HTML trip tester (`local-ui/index.html`) served with Python HTTP server
- Optional PyCharm remote debugging for Lambdas in SAM Docker
- Local smoke test script for SAM startup + endpoint check

## Prerequisites

- Python 3.12+ (3.14 also works for local tooling)
- AWS SAM CLI
- Docker Desktop (running)
- `curl`
- Optional for smoke test script: `pyenv` + a pyenv virtualenv

## 1. Install Python Dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 2. Run SAM Local API (Local-Test Routes Enabled)

From repo root:

```bash
sam build -t infra/template.yaml --no-cached
sam local start-api -t infra/template.yaml --parameter-overrides EnableLocalTestTools=true --port 3000
```

Notes:
- `EnableLocalTestTools=true` is required for the local-only endpoint.
- Local endpoint used by UI: `GET /local/trip-preview`.

## 3. Run the Local HTML UI with a Simple Python Server

In a second terminal from repo root:

```bash
python3 -m http.server 8080 --directory local-ui
```

Open:

- `http://127.0.0.1:8080`

How it works:
- The page collects `from` / `to` addresses.
- It calls `http://127.0.0.1:3000/local/trip-preview?...`.
- It renders the returned route details and map locally.

## 4. Quick Endpoint Check (Without UI)

```bash
curl "http://127.0.0.1:3000/local/trip-preview?from_address=Seattle,WA&to_address=Portland,OR"
```

Expected: JSON response containing `"local_only": true`.

## 5. Optional: PyCharm Debugging (SAM Docker)

### PyCharm Debug Server

Create `Python Debug Server` config with:
- Host: `localhost`
- Port: `5891`
- Path mapping (one only):
  - Local: `<repo-root>`
  - Remote: `/var/task`

### Start SAM with debugger enabled

```bash
DEBUG=true PYCHARM_DEBUG_HOST=host.docker.internal PYCHARM_DEBUG_PORT=5891 \
sam local start-api -t infra/template.yaml --parameter-overrides EnableLocalTestTools=true --port 3000
```

## 6. Optional: Preflight + Smoke Test Scripts

Preflight:

```bash
python3 tools/preflight_debug.py
```

Smoke test (pyenv-based):

```bash
make test-local PYENV_ENV=<your-pyenv-env>
```

What smoke test does:
- Builds SAM app
- Starts `sam local start-api`
- Calls local trip endpoint
- Fails if endpoint is not ready/healthy

## 7. Local Env Files

Use templates from `env/examples/`:
- `env/examples/.env.local.example`
- `env/examples/.env.develop.example`
- `env/examples/.env.staging.example`
- `env/examples/.env.prod.example`

Recommended local workflow:

```bash
cp env/examples/.env.local.example .env.local
set -a; source .env.local; set +a
```

Do not commit `.env*` files with real values.

## 8. Troubleshooting

- `Error: Running AWS SAM projects locally requires Docker`:
  - Start Docker Desktop and retry.
- UI loads but requests fail:
  - Ensure SAM is running on port `3000`.
  - Ensure endpoint started with `EnableLocalTestTools=true`.
- Debugger attaches but breakpoints do not hit:
  - Check path mapping is exactly `<repo-root> -> /var/task` (single mapping only).
- `pytest` not found:
  - Install dev tooling in your active env or use compile checks/scripts first.

## 9. Local-Only Safety

- Keep local tooling isolated to local runs.
- Do not enable `EnableLocalTestTools=true` in production deploys.
