# SAM Local + PyCharm Debugging

## Common breakpoint pitfall

A common failure mode with SAM local + PyCharm is:

- debugger reports connected
- Lambda runs and returns
- breakpoints are never hit

This is usually path mapping mismatch.

## Correct path mapping for this project

Use exactly one mapping in PyCharm Python Debug Server:

- Local path: `<repo-root>`
- Remote path: `/var/task`

Because SAM mounts this project so module files resolve under `/var/task/...`.

## Local debug run

1. Start PyCharm debug server on `localhost:5891`.
2. Export debug env vars and run SAM:

```bash
DEBUG=true PYCHARM_DEBUG_HOST=host.docker.internal PYCHARM_DEBUG_PORT=5891 \
sam local start-api -t infra/template.yaml \
  --parameter-overrides EnableLocalTestTools=true \
  --port 3000
```

3. Hit endpoint:

```bash
curl "http://127.0.0.1:3000/local/trip-preview?from_address=Seattle,WA&to_address=Portland,OR"
```

## Preflight and smoke-test helpers

- `python3 tools/preflight_debug.py`
- `make test-local PYENV_ENV=<your-pyenv-env>`
