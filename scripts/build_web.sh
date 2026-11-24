#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --no-web-resources-cdn "$@"
python3 scripts/package_web.py build/web
