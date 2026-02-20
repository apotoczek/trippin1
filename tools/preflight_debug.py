#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = REPO_ROOT / "infra" / "template.yaml"
LOCAL_HANDLER = REPO_ROOT / "src" / "lambdas" / "local_trip_preview" / "app.py"


def main() -> None:
    if not TEMPLATE.exists():
        print("[FAIL] Missing infra/template.yaml")
        sys.exit(1)

    if not LOCAL_HANDLER.exists():
        print("[FAIL] Missing src/lambdas/local_trip_preview/app.py")
        sys.exit(1)

    print("[OK] Layout looks good.")
    print("\nCanonical PyCharm mapping (ONE mapping only):")
    print(f"  Local : {REPO_ROOT}")
    print("  Remote: /var/task")
    print("\nSAM packages deps from requirements.txt (CodeUri: ../ from infra/template.yaml).")


if __name__ == "__main__":
    main()
