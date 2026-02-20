import os


def maybe_enable_pycharm_debugger(logger):
    """Attach PyCharm debugger from inside SAM local Docker runtime.

    Enable by setting:
      - DEBUG=true
      - PYCHARM_DEBUG_HOST (default: host.docker.internal)
      - PYCHARM_DEBUG_PORT (default: 5891)

    Canonical PyCharm mapping for this project:
      - Local : <repo-root>
      - Remote: /var/task
    """
    if os.environ.get("DEBUG", "false").lower() != "true":
        return

    host = os.environ.get("PYCHARM_DEBUG_HOST", "host.docker.internal")
    port = int(os.environ.get("PYCHARM_DEBUG_PORT", "5891"))

    try:
        import pydevd_pycharm  # type: ignore
    except ImportError as exc:
        logger.warning("DEBUG=true but pydevd-pycharm is not installed in Lambda build: %s", exc)
        return

    logger.warning("Connecting to PyCharm debug server at %s:%s", host, port)
    pydevd_pycharm.settrace(
        host,
        port=port,
        stdout_to_server=False,
        stderr_to_server=False,
        suspend=False,
    )
    logger.warning("Connected to PyCharm debugger")
