#!/usr/bin/env bash
set -euo pipefail
# Minimal builder entrypoint: print environment and drop to shell
echo "[builder entrypoint] starting..."
exec "$@"
