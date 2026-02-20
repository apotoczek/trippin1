.PHONY: debug-preflight test-local

debug-preflight:
	python3 tools/preflight_debug.py

test-local:
	@if [ -z "$(PYENV_ENV)" ]; then \
		echo "PYENV_ENV is required. Usage: make test-local PYENV_ENV=<pyenv-env-name>"; \
		exit 1; \
	fi
	./tools/test_local_sam.sh "$(PYENV_ENV)"
