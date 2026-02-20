#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <pyenv-environment-name>"
  exit 1
fi

PYENV_ENV="$1"
PORT=3000
BASE_URL="http://127.0.0.1:${PORT}"
TEST_PATH="/local/trip-preview?from_address=San+Francisco%2C+CA&to_address=San+Jose%2C+CA"
TIMEOUT_SECONDS=45
SAM_LOG=".sam_test.log"

log() { echo "[sam-test] $*"; }
fail() { echo "[sam-test][FAIL] $*" >&2; exit 1; }

cleanup() {
  if [[ -n "${SAM_PID:-}" ]] && ps -p "$SAM_PID" >/dev/null 2>&1; then
    log "Stopping sam local (pid=$SAM_PID)"
    kill "$SAM_PID"
    wait "$SAM_PID" 2>/dev/null || true
  fi
  if [[ -n "${PREV_PYENV_VERSION:-}" ]]; then
    pyenv shell "$PREV_PYENV_VERSION" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

command -v pyenv >/dev/null || fail "pyenv not found"
command -v sam >/dev/null || fail "AWS SAM CLI not found"
command -v curl >/dev/null || fail "curl not found"

if ! pyenv prefix "$PYENV_ENV" >/dev/null 2>&1; then
  fail "pyenv environment '$PYENV_ENV' does not exist"
fi

PREV_PYENV_VERSION="$(pyenv version-name || true)"
log "Activating pyenv environment: $PYENV_ENV"
pyenv shell "$PYENV_ENV"

log "Running sam build"
rm -rf .aws-sam/build
sam build -t infra/template.yaml --no-cached >"$SAM_LOG" 2>&1

log "Starting sam local start-api on port ${PORT}"
sam local start-api -t infra/template.yaml \
  --parameter-overrides EnableLocalTestTools=true \
  --port "$PORT" >>"$SAM_LOG" 2>&1 &
SAM_PID=$!

log "Waiting for API readiness"
START_TS=$(date +%s)
until curl -sf "${BASE_URL}${TEST_PATH}" >/dev/null 2>&1; do
  sleep 1
  NOW_TS=$(date +%s)
  if (( NOW_TS - START_TS > TIMEOUT_SECONDS )); then
    log "sam local output:"
    sed 's/^/  | /' "$SAM_LOG" || true
    fail "API did not become ready within ${TIMEOUT_SECONDS}s"
  fi
done

RESPONSE="$(curl -sf "${BASE_URL}${TEST_PATH}")"
log "Response: ${RESPONSE}"

if echo "$RESPONSE" | grep -q '"local_only"[[:space:]]*:[[:space:]]*true'; then
  log "Local trip preview check passed"
else
  fail "Unexpected response: ${RESPONSE}"
fi

log "SAM local smoke test PASSED"
